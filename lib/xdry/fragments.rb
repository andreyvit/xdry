
module XDry

  class OVarType
    def self.parse type_decl
      type_decl = type_decl.strip
      case type_decl
      when /^id$/
        OIdVarType.new
      when /^(?:unsigned\s+|signed\s+|long\s+)?\w+$/
        OSimpleVarType.new(type_decl.gsub(/\s+/, ' '))
      when /^(\w+)\s*\*$/
        class_name = $1
        OPointerVarType.new(class_name)
      else
        raise StandardError, "Cannot parse Obj-C type: '#{type_decl}'"
      end
    end
  end

  class OIdVarType < OVarType
    def to_s
      "id"
    end

    def default_property_retainment_policy; 'assign'; end
  end

  class OSimpleVarType < OVarType
    attr_reader :name

    def initialize name
      @name = name
    end

    def to_s
      "#{@name}"
    end

    def default_property_retainment_policy; ''; end
  end

  class OPointerVarType < OVarType
    attr_reader :name
    attr_accessor :type_hint

    def initialize name
      @name = name
    end

    def to_s
      "#{@name} *"
    end

    def default_property_retainment_policy; 'retain'; end
  end

  class Fragment
    attr_accessor :line_no

    def initialize
      @tags = Set.new
    end

    def tags
      @tags.dup
    end

    def tags= new_tags
      @tags = Set.new(new_tags)
    end

    def tagged_with? tag
      @tags.include? tag
    end

    def method_missing id, *args, &block
      if id.to_s =~ /^with_(.*)$/
        send("#{$1}=", *args, &block)
        self
      else
        super(id, *args, &block)
      end
    end

  end

  class OFieldDef < Fragment
    attr_reader :name, :type

    def initialize name, type
      super()
      @name, @type = name, type
    end

    def persistent?
      tagged_with? 'persistent'
    end

    def to_s
      "#{@type} #{@name}"
    end

    def to_source
      "#{@type} _#{@name};"
    end
  end

  class OPropertyDef < Fragment
    attr_reader :name, :type

    def initialize name, type
      super()
      @name, @type = name, type
    end

    def outlet?
      tagged_with? 'outlet'
    end

    def to_s
      "#{if outlet? then 'IBOutlet ' else '' end}#{@type} #{@name}"
    end

    def to_source
      retainment = case @type.default_property_retainment_policy
        when '' then ''
        else ', ' + @type.default_property_retainment_policy
      end
      iboutlet = if outlet? then "IBOutlet " else '' end
      "@property(nonatomic#{retainment}) #{iboutlet}#{@type} #{@name};"
    end
  end

  class OSelectorDef

    def self.parse string
      string = string.strip
      if string =~ /^\w+$/
        OSimpleSelectorDef.new(string)
      else
        comps = string.split(/\s+(?!\*)/).collect do |component_string|
          if component_string =~ /^(\w+:)\s*(?:\(([^)]+)\)\s*)?(\w*)$/
            keyword, type_decl, arg_name = $1, $2, $3
            type = if type_decl then OVarType.parse(type_decl) else nil end
            OSelectorComponent.new(keyword, arg_name, type)
          else
            raise StandardError, "Cannot parse selector component '#{component_string}' for selector '#{string}'"
          end
        end
        OCompoundSelectorDef.new(comps)
      end
    end

  end

  class OSimpleSelectorDef < OSelectorDef

    attr_reader :selector

    def initialize selector
      @selector = selector
    end

    def simple?; true; end

    def to_s
      @selector
    end

  end

  class OSelectorComponent
    attr_reader :keyword, :arg_name, :type

    def initialize keyword, arg_name, type
      raise StandardError, "keyword must end with a colon: '#{keyword}'" unless keyword[-1] == ?:
      @keyword, @arg_name, @type = keyword, arg_name, type
    end

    def keyword_without_colon
      @keyword_without_colon ||= @keyword.sub(/:$/, '')
    end

    def has_type?
      not @type.nil?
    end

    def to_s
      if has_type?
        "#{keyword}(#{@type})#{@arg_name}"
      else
        "#{keyword}#{@arg_name}"
      end
    end
  end

  class OCompoundSelectorDef < OSelectorDef
    attr_reader :components

    def initialize components
      @components = components.freeze
    end

    def selector
      @selector ||= @components.collect { |comp| comp.keyword }.join("")
    end

    def simple?; false; end

    def to_s
      @components.collect { |comp| comp.to_s }.join(" ")
    end

  end

  class OMethodHeader < Fragment
    attr_reader :selector_def, :ret_type

    def initialize selector_def, ret_type
      @selector_def, @ret_type = selector_def, ret_type
    end

    def selector
      @selector_def.selector
    end

    def to_s
      "- (#{@ret_type})#{selector_def}"
    end

  end

end
