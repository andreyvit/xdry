
module XDry

  class InsertionPoint

    attr_reader :method, :node

    def initialize
      find!
    end

    def insert patcher, lines
      raise StandardError, "#{self.class.name} has not been found but trying to insert" unless found?
      patcher.send(@method, @node.pos, lines)
    end

    def found?
      not @method.nil?
    end

  protected

    def before node
      @method = :insert_before
      @node = node
    end

    def after node
      @method = :insert_after
      @node = node
    end

    def try insertion_point
      if insertion_point.found?
        @method, @node = insertion_point.method, insertion_point.node
        true
      else
        false
      end
    end

    def find!
    end

  end

  class ImplementationStartIP < InsertionPoint

    def initialize oclass
      @oclass = oclass
      super()
    end

    def find!
      after @oclass.main_implementation.start_node
    end

  end

  class MultiIP < InsertionPoint

    def initialize *insertion_points
      @insertion_points = insertion_points
    end

    def find!
      @insertion_points.detect { |ip| try ip }
    end

  end

end
