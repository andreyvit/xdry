
module XDry

  class BaseFileRef

    attr_reader :positions

    def initialize
      @positions = []
    end

    def add_pos! pos
      @positions << pos
    end

    def fixup_positions! after_line_no, offset
      @positions.each { |pos| pos.fixup! after_line_no, offset }
    end

  end

  class FileRef < BaseFileRef

    attr_reader :path

    def initialize path
      super()
      @path = path
    end

    def read
      open(@path) { |f| f.read }
    end

  end

  class TestFileRef < BaseFileRef
    attr_reader :path

    def initialize path, source
      super()
      @path, @source = path, source
    end

    def read
      @source
    end
  end

  class Pos
    attr_reader :file_ref, :line_no
    attr_accessor :scope_before, :scope_after

    def initialize file_ref, line_no
      @file_ref = file_ref
      @line_no  = line_no
      @file_ref.add_pos! self
    end

    def file_path
      @file_ref.path
    end

    def fixup! after_line_no, offset
      if @line_no > after_line_no
        @line_no += offset
      end
    end

    def to_s
      "#{File.basename(@file_ref.path)}:#{@line_no}"
    end
  end

end
