
module XDry

  class Node
    attr_accessor :pos, :indent

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
      raise StandardError, "type cannot be nil for prop #{name}" if type.nil?
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

  class NMethodStart < Node
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

  class SynthesizeItem

    attr_reader :property_name, :field_name

    def initialize property_name, field_name = nil
      @property_name, @field_name = property_name, field_name
    end

    def has_field_name?
      not @field_name.nil?
    end

    def to_s
      if has_field_name?
        "#{property_name}=#{field_name}"
      else
        "#{property_name}"
      end
    end

    def self.parse string
      case string
        when /^(\w+)$/             then SynthesizeItem.new($1, nil)
        when /^(\w+)\s*=\s*(\w+)$/ then SynthesizeItem.new($1, $2)
      end
    end

  end

  class NSynthesize < Node

    attr_reader :items

    def initialize items
      @items = items
    end

    def item_for_property_named property_name
      @items.find { |item| item.property_name == property_name }
    end

    def to_s
      "@synthesize " + @items.join(", ") + ";"
    end

    def self.parse string
      if string =~ /^@synthesize\s+(.*);$/
        NSynthesize.new($1.strip.split(/\s+,\s+/).collect { |s| SynthesizeItem.parse(s) }.compact)
      end
    end

  end

  class NOpeningBrace < Node
  end

  class NMethodEnd < Node
  end

  class NReleaseCall < Node
    attr_reader :expr

    def initialize expr
      @expr = expr
    end
  end

  class NSuperCall < Node
  end

end
