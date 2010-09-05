
module XDry

  class ItemPatcher

    attr_reader :item
    attr_reader :patcher

    def initialize patcher
      @patcher = patcher
      find!
      yield @item if block_given? && found?
    end

    def found?
      not item.nil?
    end

  protected

    def find
    end

    def insertion_point
    end

    def new_code
    end

  private

    def find!
      @item = find
      if @item.nil?
        patch!
        @item = find
        raise AssertionError, "#{seld.class.name} cannot find item even after adding a new one" if @item.nil?
      end
    end

    def patch!
      insertion_point.insert patcher, new_code
    end

  end

  class MethodPatcher < ItemPatcher

    attr_reader :oclass
    attr_reader :insertion_point
    attr_reader :new_code

    def initialize patcher, oclass, selector, insertion_point, new_code
      @oclass = oclass
      @selector = selector
      @insertion_point = insertion_point
      @new_code = new_code
      super(patcher)
    end

  protected

    def find
      find_method_impl_by_selector(@selector)
    end

    def find_method_impl_by_selector selector
      m = oclass.find_method(selector)
      m && (m.has_impl? ? m : nil)
    end

  end

end
