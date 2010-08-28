require 'set'

module XDry

  class Parser

    def to_s
      "#{self.class.name}"
    end

  end

  class PGlobal < Parser

    def parse_line! line, eol_comments
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
      end
    end

  end

  class PInterfaceFields < Parser

    def initialize
      @tags = Set.new
    end

    def parse_line! line, eol_comments
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
      end
    end

  private

    def process_type_hint field_def, eol_comments
      field_def.tags = @tags.to_a

      case field_def.type.name
      when 'NSArray'
        if eol_comments =~ %r`//\s*of\s+(\w+)`
          field_def.type.type_hint = $1
        end
      end

      field_def
    end
  end

  class PInterfaceHeader < Parser

    def parse_line! line, eol_comments
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

      when /^@synthesize/
        yield NSynthesize.parse(line)
      end
    end

  end

end
