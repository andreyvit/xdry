require 'set'

module XDry

  class State
    attr_reader :context

    def initialize context, parent_state
      @context = context
      @parent_state = parent_state
    end

    def to_s
      "#{self.class.name} #{@context}"
    end

    def add! fragment
      @context.add! fragment
    end
  end

  class SGlobal < State

    def process_header_line! line
      case line
        when /^@interface\s+(\w+)\s*;/
          name = $1
          puts "PREDEF interface #{name}"
        when /^@protocol\s+(\w+)\s*;/
          name = $1
          puts "PREDEF protocol #{name}"

        when /^@interface\s+(\w+)/  #\s*(?:[:(][\w:(),\s]*)?
          name, supers, postfix = $1, $2, $'

          oclass = @context.lookup_class(name)
          sinterface = SInterfaceHeader.new(oclass, self)
          if postfix.strip =~ /\{/
            yield SInterfaceHeaderVars.new(oclass, sinterface)
          else
            yield sinterface
          end

        when /^@protocol\s+(\w+)\s*;/
          puts "PREDEF protocol #{$1}"
      end
    end

  end

  class SInterfaceHeaderVars < State

    def initialize context, parent_state
      super
      @tags = Set.new
    end

    def process_header_line! line
      case line
      when /\}/
        yield @parent_state
      when %r~^//\s*persistent$~
        @tags << 'persistent'
      when ''
        @tags.clear
      when /^(\w+)\s+(\w+)\s*;/
        type_name, field_name = $1, $2
        yield OFieldDef.new(field_name, OSimpleVarType.new(type_name)).with_tags(@tags.to_a)
      when /^(\w+)\s*\*\s*(\w+)\s*;/
        type_name, field_name = $1, $2
        yield OFieldDef.new(field_name, OPointerVarType.new(type_name)).with_tags(@tags.to_a)
      end
    end
  end

  class SInterfaceHeader < State

    def process_header_line! line
      case line
      when /@end/
        yield @parent_state
      when /^@property(\s*\([\w\s,]*\))?\s+(IBOutlet\s+)?(\w+)\s*\*\s*(\w+)\s*;$/
        property_flags, iboutlet, type_name, property_name = $1, $2, $3, $4
        yield OPropertyDef.new(property_name, OPointerVarType.new(type_name))
      when /^@property(\s*\([\w\s,]*\))?\s+(IBOutlet\s+)?(\w+)\s+(\w+)\s*;$/
        property_flags, iboutlet, type_name, property_name = $1, $2, $3, $4
        yield OPropertyDef.new(property_name, OSimpleVarType.new(type_name))
      end
    end

  end

end
