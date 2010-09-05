require 'generator'
require 'stringio'

module XDry

  class ParsingDriver
    attr_accessor :verbose

    def initialize oglobal
      @oglobal = oglobal
      @verbose = false
    end

    def parse_file file_name
      gen = Generator.new { |g|
        file_ref = FileRef.new(file_name)
        File.open(file_name) do |file|
          new_lines_generator g, file_ref, file
        end
      }
      parse_data_in_file_scope gen
    end

    def parse_string file_name, source
      gen = Generator.new { |g|
        file_ref = TestFileRef.new(file_name, source)
        new_lines_generator g, file_ref, StringIO.new(source)
      }
      parse_data_in_file_scope gen
    end

    def parse_fragment file_ref, lines, start_lineno, start_scope
      gen = Generator.new { |g|
        new_lines_from_array_generator g, file_ref, start_lineno, lines
      }
      parse_data_in_scopes gen, start_scope.all_scopes
    end

  private

    def parse_data_in_file_scope gen
      parse_data_in_scopes gen, [@oglobal.new_file_scope]
    end

    def parse_data_in_scopes gen, scopes
      scope_stack = ScopeStack.new(scopes)
      scope_stack.verbose = @verbose
      while gen.next?
        orig_line, line, pos, eol_comments, indent = gen.next
        puts "        #{pos} #{orig_line}" if @verbose
        pos.scope_before = scope_stack.current_scope
        scope_stack.parse_line line, eol_comments, indent do |scope, child|
          # child is a Node or a Scope
          if child.is_a? Node
            child.pos = pos
            child.indent = indent
          end

          puts "#{scope} << #{child}" if @verbose
          scope << child
        end
        pos.scope_after = scope_stack.current_scope
      end
    end

    def new_lines_generator g, file_ref, io
      line_no = 0
      io.each_line do |line|
        line_no += 1
        orig_line, line, eol_comments, indent = split_line(line)
        g.yield [orig_line, line, Pos.new(file_ref, line_no), eol_comments, indent]
      end
    end

    def new_lines_from_array_generator g, file_ref, start_lineno, lines
      line_no = start_lineno - 1
      lines.each do |line|
        line_no += 1
        orig_line, line, eol_comments, indent = split_line(line.dup)
        g.yield [orig_line, line, Pos.new(file_ref, line_no), eol_comments, indent]
      end
    end

    def split_line line
      orig_line = line.dup
      line.strip!

      # strip end-of-line comments, but keep comment lines
      eol_comments = ''
      line_without_comments = line.sub(%r`//.*$`) { eol_comments = $&; '' }
      unless line_without_comments.empty?
        line = line_without_comments
      end

      indent = if orig_line =~ /^(\s+)/ then $1 else '' end
      return [orig_line, line, eol_comments, indent]
    end

  end

end
