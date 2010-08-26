
module XDry

  class OVarType
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

end
