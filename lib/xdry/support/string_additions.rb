
module XDry

  module StringAdditions

    def blank?
      self =~ /^\s*$/
    end

  end

  String.send(:include, StringAdditions)

end
