require 'strscan'

module XDry

  class SelectorDef

    def self.parse string
      string = string.strip
      if string =~ /^\w+$/
        SimpleSelectorDef.new(string)
      else
        ss = StringScanner.new(string)
        comps = []
        while not ss.eos?
          keyword = ss.scan(/\w+\s*:/) or raise(StandardError, "Cannot parse selector '#{string}': keyword expected at '#{ss.rest}'")
          keyword = keyword.gsub(/\s/, '')

          ss.skip(/\s+/)
          if ss.skip(/\(/)
            res = ss.scan_until(/\)/) or raise(StandardError, "Cannot parse selector '#{string}': missing closing paren at '#{ss.rest}'")
            type_decl = res[0..-2].strip
          else
            type_decl = nil
          end

          ss.skip(/\s+/)
          unless ss.match?(/\w+\s*:/)
            arg_name = ss.scan(/\w+/)
          else
            arg_name = nil
          end
          ss.skip(/\s+/)

          type = if type_decl then VarType.parse(type_decl) else nil end
          comps << SelectorComponent.new(keyword, arg_name, type)
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

    def var_name_after_keyword keyword
      nil
    end

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

    def var_name_after_keyword keyword
      comp = @components.find { |comp| comp.keyword == keyword }
      comp && comp.arg_name
    end

  end

end
