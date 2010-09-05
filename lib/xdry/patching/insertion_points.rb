
module XDry

  class InsertionPoint

    attr_reader :method, :node, :ip

    def initialize
      find!
    end

    def insert patcher, lines
      raise StandardError, "#{self.class.name} has not been found but trying to insert" unless found?
      patcher.send(@method, @node.pos, wrap(lines), @indent)
    end

    def found?
      not @method.nil?
    end

  protected

    def wrap lines
      lines
    end

    def before node
      @method = :insert_before
      @node = node
      @indent = node.indent
    end

    def after node
      @method = :insert_after
      @node = node
      @indent = node.indent
    end

    def indented_before node
      before node
      @indent = @indent + INDENT_STEP
    end

    def indented_after node
      after node
      @indent = @indent + INDENT_STEP
    end

    def try insertion_point
      if insertion_point.found?
        @method, @node, @ip = insertion_point.method, insertion_point.node, insertion_point
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

  class BeforeImplementationStartIP < InsertionPoint

    def initialize oclass
      @oclass = oclass
      super()
    end

    def find!
      before @oclass.main_implementation.start_node
    end

  end

  class BeforeSuperCallIP < InsertionPoint

    def initialize scope
      @scope = scope
      super()
    end

    def find!
      child_node = @scope.children.find { |child| child.is_a? NSuperCall }
      if child_node.nil?
        indented_before @scope.ending_node
      else
        before child_node
      end
    end

  end

  class BeforeReturnIP < InsertionPoint

    def initialize scope
      @scope = scope
      super()
    end

    def find!
      child_node = @scope.children.find { |child| child.is_a? NReturn }
      if child_node.nil?
        before @scope.ending_node
      else
        before child_node
      end
    end

  end

  class AfterDefineIP < InsertionPoint

    def initialize scope
      @scope = scope
      super()
    end

    def find!
      child_nodes = @scope.children.select { |child| child.is_a? NDefine }
      unless child_nodes.empty?
        after child_nodes.last
      end
    end

  end

  class InsideConstructorIfSuperIP < InsertionPoint

    def initialize scope
      @scope = scope
      super()
    end

    def find!
      if_start_node = @scope.children.find { |child| child.is_a? NSuperCall }
      if if_start_node.nil?
        indented_before @scope.ending_node
      else
        if_end_node = @scope.children.find { |child| child.is_a?(NClosingBrace) && child.indent == if_start_node.indent }
        if if_end_node.nil?
          indented_after if_start_node
        else
          indented_before if_end_node
        end
      end
    end

  end

  class MultiIP < InsertionPoint

    def initialize *insertion_points
      @insertion_points = insertion_points
      @last_before = []
      @last_after  = []
      super()
    end

    def wrap_if_last! before, after
      @last_before = before
      @last_after  = after
    end

    def wrap_with_empty_lines_if_last!
      wrap_if_last! [""], [""]
    end

    def find!
      @insertion_points.detect { |ip| try ip }
    end

    def wrap lines
      if @ip == @insertion_points.last
        @last_before + lines + @last_after
      else
        lines
      end
    end

  end

end
