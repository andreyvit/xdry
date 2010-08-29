
module XDry

  module SymbolAdditions

    def to_proc
      proc { |obj, *args| obj.send(self, *args) }
    end

  end

  Symbol.send(:include, SymbolAdditions)

end
