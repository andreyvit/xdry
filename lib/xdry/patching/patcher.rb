
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

      # collapse leading/trailing empty lines with the empty lines that already exist
      # in the source code

      desired_leading_empty_lines = new_lines.prefix_while(&:blank?).length
      actual_leading_empty_lines  = lines[0..line_index].suffix_while(&:blank?).length
      leading_lines_to_remove     = [actual_leading_empty_lines, desired_leading_empty_lines].min
      new_lines = new_lines[leading_lines_to_remove .. -1]

      # if all lines were empty, the number of trailing empty lines might have changed
      # after removal of some leading lines, so we compute this after the removal
      desired_trailing_empty_lines = new_lines.suffix_while(&:blank?).length
      actual_trailing_empty_lines  = lines[line_index+1..-1].prefix_while(&:blank?).length
      trailing_lines_to_remove     = [actual_trailing_empty_lines, desired_trailing_empty_lines].min
      new_lines = new_lines[0 .. -(trailing_lines_to_remove+1)]

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

    def retrieve!
      result = {}
      for file_ref, lines in @patched
        result[file_ref.path] = lines.join("")
      end
      @patched = {}
      return result
    end

  private

    def patched_lines_of file_ref
      @patched[file_ref] ||= load_lines_of(file_ref)
    end

    def load_lines_of file_ref
      file_ref.read.lines.collect
    end

  end

end
