
module XDry

  class VarType
    def self.parse type_decl
      type_decl = type_decl.strip
      case type_decl
      when /^id$/
        IdVarType.new
      when /^id\s*<\s*(\w+)\s*>$/
        IdVarType.new($1)
      when /^(?:unsigned\s+|signed\s+|long\s+)?\w+$/
        SimpleVarType.new(type_decl.gsub(/\s+/, ' '))
      when /^(\w+)\s*\*$/
        class_name = $1
        PointerVarType.new(class_name)
      when /^(\w+)\s*\*\s*\*$/
        class_name = $1
        PointerPointerVarType.new(class_name)
      else
        puts "!! Cannot parse Obj-C type: '#{type_decl}'"
        return UnknownVarType.new(type_decl)
      end
    end

    def to_source_with_space
      needs_space? ? "#{to_s} " : "#{to_s}"
    end

    def needs_space?; true; end
  end

  class IdVarType < VarType
    attr_reader :protocol

    def initialize protocol=nil
      @protocol = protocol
    end

    def to_s
      if @protocol.nil?
        "id"
      else
        "id<#{@protocol}>"
      end
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

  class PointerPointerVarType < VarType
    attr_reader :name
    attr_accessor :type_hint

    def initialize name
      @name = name
    end

    def to_s
      "#{@name} **"
    end

    def needs_space?; false; end

    def default_property_retainment_policy; 'retain'; end
  end

  class UnknownVarType < VarType
    attr_reader :name
    attr_accessor :type_hint

    def initialize name
      @name = name
    end

    def to_s
      @name
    end

    def needs_space?; true; end

    def default_property_retainment_policy; 'retain'; end
  end

end
