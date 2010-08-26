require 'generator'

module XDry

  class Pos
    def initialize line_no
    end
  end

  class Parser
    def initialize oglobal
      @oglobal = oglobal
    end

    def new_lines_generator file_name
      Generator.new { |g|
        File.open(file_name) do |file|
          file.each_line do |line|
            orig_line = line.dup
            line.strip!

            # strip end-of-line comments, but keep comment lines
            eol_comments = ''
            line_without_comments = line.sub(%r`//.*$`) { eol_comments = $&; '' }
            unless line_without_comments.empty?
              line = line_without_comments
            end

            g.yield [orig_line, line, eol_comments]
          end
        end
      }
    end

    def parse_header file_name
      gen = new_lines_generator(file_name)
      state = SGlobal.new(@oglobal, nil)
      while gen.next?
        orig_line, line, eol_comments = gen.next
        puts "        #{orig_line}" if DEBUG
        state.process_header_line!(line, eol_comments) do |something|
          case something
          when State
            puts "#{state} --> #{something}" if DEBUG
            state = something
          when Fragment
            puts "#{state.context} << #{something}" if DEBUG
            state.add! something
          else
            raise StandardError, "Shit emitted from process_header_line! (#{something.class.name}) for line '#{line}'"
          end
        end
      end
    end
  end

end
