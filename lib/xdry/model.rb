
module XDry

  class OGlobal

    def initialize
      @names_to_classes = {}
    end

    def classes
      @names_to_classes.values
    end

    def lookup_class name
      @names_to_classes[name] ||= OClass.new(self, name)
    end
  end

  class OClass
    attr_reader :name, :field_defs, :attributes, :methods

    def initialize oglobal, name
      @oglobal, @name = oglobal, name

      @names_to_attributes = {}
      @attributes = []

      @selectors_to_methods = {}
      @methods = []

      @field_defs = []
      @property_defs = []
    end

    def add! fragment
      case fragment
      when OFieldDef
        @field_defs << fragment
        attr_name = fragment.name.gsub /^_/, ''
        lookup_attribute(attr_name).add_field_def! fragment
      when OPropertyDef
        @property_defs << fragment
        attr_name = fragment.name
        lookup_attribute(attr_name).add_property_def! fragment
      when OMethodHeader
        selector = fragment.selector
        lookup_method(selector).add_method_header! fragment
      else
        raise StandardError, "Unknown fragment: #{fragment}"
      end
    end

    def to_s
      "class #{name}"
    end

    def find_attribute name
      @names_to_attributes[name]
    end

    def find_method selector
      @selectors_to_methods[name]
    end

  private

    def lookup_attribute name
      @names_to_attributes[name] ||= create_attribute(name)
    end

    def lookup_method selector
      @selectors_to_methods[selector] ||= create_method(selector)
    end

    def create_attribute name
      a = OAttribute.new(self, name)
      @attributes << a
      return a
    end

    def create_method selector
      a = OMethod.new(selector)
      @methods << a
      return a
    end

  end

  class OAttribute
    attr_reader :name

    def initialize oclass, name
      @oclass, @name = oclass, name

      @field_def    = nil
      @property_def = nil
    end

    def field_name
      @field_def.name
    end

    def add_field_def! field_def
      @field_def = field_def
    end

    def add_property_def! property_def
      @property_def = property_def
    end

    def has_field_def?
      not @field_def.nil?
    end

    def has_property_def?
      not @property_def.nil?
    end

    def new_property_def
      OPropertyDef.new(name, type)
    end

    def new_field_def
      OFieldDef.new(name, type)
    end

    def persistent?
      @field_def && @field_def.persistent?
    end

    def type
      if @property_def
        @property_def.type
      elsif @field_def
        @field_def.type
      else
        nil
      end
    end

    def to_s
      "#{type} #{name}"
    end
  end

  class OMethod
    attr_reader :selector, :header

    def initialize selector
      @selector = selector
      @header, @implementation = nil, nil
    end

    def add_method_header! method_header
      @header = method_header
    end

    def ret_type
      @header.ret_type
    end

    def to_s
      @header.to_s
    end

  end

end
