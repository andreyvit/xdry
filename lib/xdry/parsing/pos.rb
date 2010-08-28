
module XDry

  class FileRef
    attr_reader :path

    def initialize path
      @path = path
    end
  end

  class Pos
    attr_reader :file_ref, :line_no

    def initialize file_ref, line_no
      @file_ref = file_ref
      @line_no  = line_no
    end

    def file_path
      @file_ref.path
    end

    def to_s
      "#{File.basename(@file_ref.path)}:#{@line_no}"
    end
  end

end
