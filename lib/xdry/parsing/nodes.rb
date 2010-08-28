
module XDry

  class Node
    attr_accessor :pos

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

  class NInterfaceFieldsEnd < Node
  end

  class NFieldDef < Node
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

  class NPropertyDef < Node
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

  class NMethodHeader < Node
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

  class NInterfaceStart < Node
    attr_reader :class_name
    def initialize class_name
      @class_name = class_name
    end
  end

  class NImplementationStart < Node
    attr_reader :class_name
    def initialize class_name
      @class_name = class_name
    end
  end

  class NEnd < Node
  end

end
