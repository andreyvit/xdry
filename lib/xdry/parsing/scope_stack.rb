
module XDry

  class ScopeStack

    attr_accessor :verbose

    def initialize root_scopes
      @stack = []
      root_scopes.each { |scope| push(scope) }
    end

    def parse_line line, eol_comments, indent
      parse_line_using_parser! line, eol_comments, indent do |node|
        unless node.nil?  # to simply code we allow the parser to yield nil when it cannot parse something
          # update the scope based on this new node
          while @current_scope.ends_after? node
            @current_scope << node
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

    def current_scope
      @current_scope
    end

  private

    def parse_line_using_parser! line, eol_comments, indent
      parsed = false
      @current_scope.parser.parse_line! line, eol_comments, indent do |node|
        parsed = true
        yield node
      end
      unless parsed
        yield NLine.new(line)
      end
    end

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
      puts "#{old_scope} --> #{@current_scope}" if @verbose
    end

  end

end
