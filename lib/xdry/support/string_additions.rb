
module XDry

  module StringAdditions

    def blank?
      self =~ /^\s*$/
    end
    
    def capitalized_identifier
      case self
        when 'id', 'uid' then upcase
        else self[0..0].upcase + self[1..-1]
      end
    end
    
    def prefixed_as_arg_name
      prefix = case self when /^[aeiou]/ then 'an' else 'a' end

      prefix + self.capitalized_identifier
    end

  end

  String.send(:include, StringAdditions)

end
