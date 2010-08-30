
module XDry

  class VarType
    def self.parse type_decl
      type_decl = type_decl.strip
      case type_decl
      when /^id$/
        IdVarType.new
      when /^(?:unsigned\s+|signed\s+|long\s+)?\w+$/
        SimpleVarType.new(type_decl.gsub(/\s+/, ' '))
      when /^(\w+)\s*\*$/
        class_name = $1
        PointerVarType.new(class_name)
      else
        raise StandardError, "Cannot parse Obj-C type: '#{type_decl}'"
      end
    end

    def to_source_with_space
      needs_space? ? "#{to_s} " : "#{to_s}"
    end

    def needs_space?; true; end
  end

  class IdVarType < VarType
    def to_s
      "id"
    end

    def default_property_retainment_policy; 'assign'; end
  end

  class SimpleVarType < VarType
    attr_reader :name

    def initialize name
      @name = name
    end

    def to_s
      "#{@name}"
    end

    def default_property_retainment_policy; ''; end
  end

  class PointerVarType < VarType
    attr_reader :name
    attr_accessor :type_hint

    def initialize name
      @name = name
    end

    def to_s
      "#{@name} *"
    end

    def needs_space?; false; end

    def default_property_retainment_policy; 'retain'; end
  end

end
