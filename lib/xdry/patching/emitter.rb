module XDry

  class Emitter
    attr_reader :lines

    def initialize
      @lines = []
      @indent = "    "
      @current_indent = ""
    end

    def << line
      case line
      when Emitter
        @lines.push *line.lines.collect { |l| @current_indent + l }
      else
        @lines << @current_indent + line
      end
    end

    def indent
      prev_indent = @current_indent
      @current_indent = @current_indent + @indent
      yield
      @current_indent = prev_indent
    end

    def empty?
      @lines.empty?
    end

    def to_s
      @lines.collect { |line| line + "\n" }.join("")
    end

    def block prefix = ''
      self << "#{prefix} {"
      self.indent { yield }
      self << "}"
    end

    def method decl, &block
      self << ""
      self.block "- #{decl}", &block
    end

    def if condition, &block
      self.block "if (#{condition})", &block
    end
  end

end
