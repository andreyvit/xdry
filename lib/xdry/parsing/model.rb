
module XDry

  class OGlobal

    def initialize
      @names_to_classes = {}
    end

    def classes
      @names_to_classes.values
    end

    def new_file_scope
      SFile.new.bind(self)
    end

    def << child
      case child
      when SInterface
        lookup_class(child.class_name).add_interface child
      when SImplementation
        lookup_class(child.class_name).add_implementation child
      end
    end

  private

    def lookup_class name
      @names_to_classes[name] ||= OClass.new(self, name)
    end
  end

  class OClass
    attr_reader :oglobal
    attr_reader :name, :field_defs, :attributes, :methods
    attr_reader :interfaces
    attr_reader :implementations

    def initialize oglobal, name
      @oglobal, @name = oglobal, name

      @names_to_attributes = {}
      @attributes = []

      @selectors_to_methods = {}
      @methods = []

      @field_defs = []
      @property_defs = []
      @interfaces = []
      @implementations = []
    end

    def add_interface child
      @interfaces << child.bind(self)
    end

    def add_implementation child
      @implementations << child.bind(self)
    end

    def main_interface
      # FIXME
      @interfaces.first
    end

    def main_implementation
      # FIXME
      @implementations.first
    end

    def << node
      case node
      when NFieldDef
        @field_defs << node
        attr_name = node.name.gsub /^_/, ''
        lookup_attribute(attr_name).add_field_def! node
      when NPropertyDef
        @property_defs << node
        attr_name = node.name
        lookup_attribute(attr_name).add_property_def! node
      when NMethodHeader
        selector = node.selector
        lookup_method(selector).add_method_header! node
      when NSynthesize
        node.items.each do |item|
          lookup_attribute(item.property_name).add_synthesize! node
        end
      when SInterfaceFields
        node.bind(self)
      when SMethodImpl
        lookup_method(node.selector).add_method_impl! node
      end
    end

    def to_s
      "class #{name}"
    end

    def find_attribute name
      @names_to_attributes[name]
    end

    def find_method selector
      @selectors_to_methods[selector]
    end

    def has_method_impl? selector
      m = find_method(selector)
      return m && m.has_impl?
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
    attr_reader :field_def

    def initialize oclass, name
      @oclass, @name = oclass, name

      @field_def    = nil
      @property_def = nil
      @synthesizes  = []
    end

    def field_name
      if @field_def
        @field_def.name
      else
        FIELD_PREFIX + name
      end
    end

    def add_field_def! field_def
      @field_def = field_def
    end

    def add_property_def! property_def
      @property_def = property_def
    end

    def add_synthesize! synthesize
      @synthesizes << synthesize
    end

    def has_field_def?
      not @field_def.nil?
    end

    def has_property_def?
      not @property_def.nil?
    end

    def has_synthesize?
      not @synthesizes.empty?
    end

    def new_property_def
      NPropertyDef.new(name, type)
    end

    def new_field_def
      NFieldDef.new(field_name, type)
    end

    def new_synthesize
      NSynthesize.new([SynthesizeItem.new(name, (field_name == name ? nil : field_name) )])
    end

    def persistent?
      @field_def && @field_def.persistent?
    end

    def type_known?
      not type.nil?
    end

    def wants_property?
      has_field_def? && field_def.wants_property?
    end

    def wants_constructor?
      has_field_def? && field_def.wants_constructor?
    end

    def getter_selector
      # FIXME: need to account for a possible selector override declared in @property
      @name
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
      traits = []
      traits << field_name if has_field_def?
      "#{type} #{name}" + (traits.empty? ? "" : " (" + traits.join(", ") + ")")
    end
  end

  class OMethod
    attr_reader :selector, :header, :impl

    def initialize selector
      @selector = selector
    end

    def add_method_header! method_header
      @header = method_header
    end

    def add_method_impl! method_impl
      @impl = method_impl.bind(self)
    end

    def has_header?
      not @header.nil?
    end

    def has_impl?
      not @impl.nil?
    end

    def ret_type
      header_or_impl.ret_type
    end

    def << child
    end

    def to_s
      header_or_impl.to_s
    end

    def header_or_impl
      @header || @impl.start_node
    end

  end

end
