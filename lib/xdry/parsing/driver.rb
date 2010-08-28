require 'generator'

module XDry

  class ParsingDriver
    attr_accessor :verbose

    def initialize oglobal
      @oglobal = oglobal
      @verbose = false
    end

    def new_lines_generator file_name
      Generator.new { |g|
        file_ref = FileRef.new(file_name)
        File.open(file_name) do |file|
          line_no = 0
          file.each_line do |line|
            line_no += 1
            orig_line = line.dup
            line.strip!

            # strip end-of-line comments, but keep comment lines
            eol_comments = ''
            line_without_comments = line.sub(%r`//.*$`) { eol_comments = $&; '' }
            unless line_without_comments.empty?
              line = line_without_comments
            end

            g.yield [orig_line, line, Pos.new(file_ref, line_no), eol_comments]
          end
        end
      }
    end

    def parse_file file_name
      gen = new_lines_generator(file_name)

      scope_stack = ScopeStack.new(@oglobal.new_file_scope)
      scope_stack.verbose = @verbose
      while gen.next?
        orig_line, line, pos, eol_comments = gen.next
        puts "        #{pos} #{orig_line}" if @verbose
        scope_stack.parse_line line, eol_comments do |scope, child|
          # child is a Node or a Scope
          child.pos = pos if child.is_a? Node
          puts "#{scope} << #{child}" if @verbose
          scope << child
        end
      end
    end
  end

end
