
module XDry

  class MethodPatcher

    attr_reader :oclass
    attr_reader :omethod
    attr_reader :patcher

    def initialize oclass, patcher
      @oclass = oclass
      @patcher = patcher
      find!
      yield @omethod if block_given? && found?
    end

    def found?
      not omethod.nil?
    end

  protected

    def find
    end

    def find_method_impl_by_selector selector
      m = oclass.find_method(selector)
      m && (m.has_impl? ? m : nil)
    end

  private

    def find!
      @omethod = find
      if @omethod.nil?
        patch!
        @omethod = find
        raise AssertionError, "#{seld.class.name} cannot find method even after adding a new one" if @omethod.nil?
      end
    end

    def patch!
      insertion_point.insert patcher, empty_implementation
    end

  end

end
