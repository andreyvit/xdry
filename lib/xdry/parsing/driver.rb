require 'generator'
require 'stringio'

module XDry

  class ParsingDriver
    attr_accessor :verbose

    def initialize oglobal
      @oglobal = oglobal
      @verbose = false
    end

    def new_lines_generator g, file_ref, io
      line_no = 0
      io.each_line do |line|
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

    def parse_file file_name
      gen = Generator.new { |g|
        file_ref = FileRef.new(file_name)
        File.open(file_name) do |file|
          new_lines_generator g, file_ref, file
        end
      }
      parse_data gen
    end

    def parse_string file_name, source
      gen = Generator.new { |g|
        file_ref = TestFileRef.new(file_name, source)
        new_lines_generator g, file_ref, StringIO.new(source)
      }
      parse_data gen
    end

  private

    def parse_data gen
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
