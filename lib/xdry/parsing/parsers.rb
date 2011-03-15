require 'set'

module XDry

  class Parser

    attr_reader :scope

    def initialize scope
      @scope = scope
    end

    def to_s
      "#{self.class.name}"
    end

  end

  class PGlobal < Parser

    def parse_line! line, eol_comments, indent
      case line
        when /^@interface\s+(\w+)\s*;/
          name = $1
        when /^@protocol\s+(\w+)\s*;/
          name = $1

        when /^@interface\s+(\w+)/  #\s*(?:[:(][\w:(),\s]*)?
          name, supers, postfix = $1, $2, $'
          yield NInterfaceStart.new(name)
          yield NOpeningBrace.new if postfix =~ /\{$/

        when /^@implementation\s+(\w+)/
          name = $1
          yield NImplementationStart.new(name)

        when /^@protocol\s+(\w+)\s*;/
          puts "PREDEF protocol #{$1}"

        when /^#define\s+(\w+)/
          word = $1
          yield NDefine.new(word)
      end
    end

  end

  class PInterfaceFields < Parser

    def initialize scope
      super
      @tags = Set.new
    end

    def parse_line! line, eol_comments, indent
      @this_line_tags = Set.new
      [[/!p\b/, 'wants-property'], [/!c\b/, 'wants-constructor']].each do |regexp, tag|
        if line =~ regexp
          marker = $&
          is_full_line = line.gsub(marker, '').strip.empty?
          klass = is_full_line ? NFullLineMarker : NPartLineMarker
          yield klass.new(marker)
          (is_full_line ? @tags : @this_line_tags) << tag
          return if is_full_line
        end
      end
      case line
      when /\}/
        yield NInterfaceFieldsEnd.new
      when %r~^//\s*persistent$~
        @tags << 'persistent'
      when ''
        @tags.clear
      when /^(\w+)\s+(\w+)\s*;/
        type_name, field_name = $1, $2
        yield process_type_hint(NFieldDef.new(field_name, SimpleVarType.new(type_name)), eol_comments)
      when /^(\w+)\s*\*\s*(\w+)\s*;/
        type_name, field_name = $1, $2
        yield process_type_hint(NFieldDef.new(field_name, PointerVarType.new(type_name)), eol_comments)
      when /^id<(\w+)>\s+(\w+)\s*;/
        type_name, field_name = $1, $2
        yield process_type_hint(NFieldDef.new(field_name, IdVarType.new()), eol_comments)
      end
    end

  private

    def process_type_hint field_def, eol_comments
      field_def.tags = (@tags + @this_line_tags).to_a

      case field_def.type
      when PointerVarType
        case field_def.type.name
        when 'NSArray'
          if eol_comments =~ %r`//\s*of\s+(\w+)`
            field_def.type.type_hint = $1
          end
        end
      end

      field_def
    end
  end

  class PInterfaceHeader < Parser

    def parse_line! line, eol_comments, indent
      case line
      when /^\{$/
        yield NOpeningBrace.new
      when /@end/
        yield NEnd.new
      when /^@property(\s*\([\w\s,]*\))?\s+(IBOutlet\s+)?(\w+)\s*\*\s*(\w+)\s*;$/
        property_flags, iboutlet, type_name, property_name = $1, $2, $3, $4
        yield NPropertyDef.new(property_name, PointerVarType.new(type_name))
      when /^@property(\s*\([\w\s,]*\))?\s+(IBOutlet\s+)?(\w+)\s+(\w+)\s*;$/
        property_flags, iboutlet, type_name, property_name = $1, $2, $3, $4
        yield NPropertyDef.new(property_name, SimpleVarType.new(type_name))
      when /^-\s*\(([^)]+)\)\s*(\w+[\w\s():*]*);$/
        ret_type_decl, selector_decl = $1, $2
        selector_def = SelectorDef.parse(selector_decl)
        ret_type = VarType.parse(ret_type_decl)
        yield NMethodHeader.new(selector_def, ret_type)

      when /^-\s*\(([^)]+)\)\s*(\w+[\w\s():*]*)\{$/
        ret_type_decl, selector_decl = $1, $2
        selector_def = SelectorDef.parse(selector_decl)
        ret_type = VarType.parse(ret_type_decl)
        yield NMethodStart.new(selector_def, ret_type)

      when /^@synthesize/
        yield NSynthesize.parse(line)
      end
    end

  end

  class PMethodImpl < Parser

    def parse_line! line, eol_comments, indent
      case line
      when /^\}$/
        if indent == scope.start_node.indent
          yield NMethodEnd.new
        else
          yield NClosingBrace.new
        end
      when /\[\s*([\w.]+)\s+release\s*\]/
        expr = $1
        yield NReleaseCall.new(expr)
      when /\bself\s*\.\s*(\w+)\s*=\s*nil\s*[,;]/
        expr = $1
        yield NReleaseCall.new(expr)
      when /\b(\w+)\s*=\s*nil\s*[,;]/
        expr = $1
        yield NReleaseCall.new(expr)
      when /\[super\s/
        yield NSuperCall.new
      when /^return\b/
        yield NReturn.new
      end
    end

  end

end
