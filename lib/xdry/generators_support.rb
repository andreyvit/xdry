
module XDry::Generators

  ALL = []

  Emitter = XDry::Emitter
  Boxing  = XDry::Boxing

  class Generator

    attr_reader :patcher
    attr_accessor :out

    def initialize config, patcher
      @config = config
      @patcher = patcher
    end

    def verbose?
      @config.verbose
    end

    def process_class oclass
      oclass.attributes.each do |oattr|
        process_attribute oclass, oattr
      end
    end

    def process_attribute oclass, oattr
    end

    def self.id(value=nil)
      @id = value if value
      @id
    end

    def self.inherited subclass
      ALL << subclass
    end

  end

end
