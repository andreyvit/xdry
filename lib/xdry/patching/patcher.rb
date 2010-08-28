
module XDry

  class Patcher

    attr_accessor :dry_run

    def initialize
      @patched = {}
      @dry_run = true
    end

    def insert_after pos, new_lines
      lines = patched_lines_of(pos.file_ref)
      line_index = pos.line_no - 1

      puts "INSERTING LINES:"
      new_lines.each { |line| puts "    #{line}" }
      puts "  AFTER LINE:"
      puts "    #{lines[line_index]}"

      lines[line_index+1 .. line_index] = new_lines.collect { |line| "#{line}\n" }
    end

    def save!
      for file_ref, lines in @patched
        original_path = file_ref.path

        new_path = if @dry_run
          ext = File.extname(original_path)
          File.join(File.dirname(original_path), File.basename(original_path, ext) + '.xdry' + ext)
        else
          original_path
        end

        text = lines.join("")
        open(new_path, 'w') { |f| f.write text }
      end
      changed_file_refs = @patched.keys
      @patched = {}
      return changed_file_refs
    end

  private

    def patched_lines_of file_ref
      @patched[file_ref] ||= load_lines_of(file_ref)
    end

    def load_lines_of file_ref
      open(file_ref.path) { |f| f.lines.collect }
    end

  end

end
