
module XDry

  class SelectorDef

    def self.parse string
      string = string.strip
      if string =~ /^\w+$/
        SimpleSelectorDef.new(string)
      else
        comps = string.split(/\s+(?!\*)/).collect do |component_string|
          if component_string =~ /^(\w+:)\s*(?:\(([^)]+)\)\s*)?(\w*)$/
            keyword, type_decl, arg_name = $1, $2, $3
            type = if type_decl then VarType.parse(type_decl) else nil end
            SelectorComponent.new(keyword, arg_name, type)
          else
            raise StandardError, "Cannot parse selector component '#{component_string}' for selector '#{string}'"
          end
        end
        CompoundSelectorDef.new(comps)
      end
    end

  end

  class SimpleSelectorDef < SelectorDef

    attr_reader :selector

    def initialize selector
      @selector = selector
    end

    def simple?; true; end

    def to_s
      @selector
    end

  end

  class SelectorComponent
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

  class CompoundSelectorDef < SelectorDef
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

end
