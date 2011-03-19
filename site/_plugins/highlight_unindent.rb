class Jekyll::HighlightBlock

  def render_pygments_with_unindent(context, code)
    code = code.split("\n").collect do |line|
      if line =~ /^ {4}/
        line[4..-1]
      else
        line
      end
    end.join("\n")
    render_pygments_without_unindent(context, code)
  end

  alias_method :render_pygments_without_unindent, :render_pygments
  alias_method :render_pygments, :render_pygments_with_unindent

end
