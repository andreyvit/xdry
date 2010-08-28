
module XDry

  class ScopeStack

    def initialize root_scope
      @stack = []
      push root_scope
    end

    def parse_line line, eol_comments
      @current_scope.parser.parse_line! line, eol_comments do |node|
        unless node.nil?  # to simply code we allow the parser to yield nil when it cannot parse something
          # update the scope based on this new node
          while @current_scope.ends_after? node
            pop
          end
          if subscope = @current_scope.subscope_for(node)
            # a subscope is added as a child of its parent scope
            yield @current_scope, subscope
            subscope.assert_bound!
            push subscope
          end
          # add the new node to the scope we have finally decided on
          yield @current_scope, node
        end
      end
    end

  private

    def push subscope
      raise StandardError, "Attempted to push a nil subscope" if subscope.nil?
      @stack.push subscope
      update_current_scope
    end

    def pop
      @stack.pop
      update_current_scope
    end

    def update_current_scope
      old_scope, @current_scope = @current_scope, @stack[-1]
      puts "#{old_scope} --> #{@current_scope}" if DEBUG
    end

  end

end
