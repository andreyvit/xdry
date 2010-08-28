
module XDry

  class Scope

    attr_reader :model
    attr_reader :children

    def initialize
      @children = []
    end

    def bind model
      raise StandardError, "#{self} already bound to #{@model} when trying to bind to #{model}" unless @model.nil?
      @model = model
      self
    end

    def assert_bound!
      raise StandardError, "#{self.class.name} hasn't been bound to a model" if @model.nil?
    end

    def parser
      @parser ||= create_parser
    end

    def subscope_for node
      nil
    end

    def << child
      raise StandardError, "#{self.class.name} hasn't been bound to a model, but is trying to accept a child #{child}" if @model.nil?
      @children << child
      @model << child
    end

    def to_s
      "#{self.class.name}:#{@model}"
    end

  protected

    def create_parser
      raise StandardError, "#{self.class.name} does not override create_parser"
    end

  end

  class SFile < Scope

    def ends_after? node
      false
    end

    def subscope_for node
      case node
      when NInterfaceStart then SInterface.new(node)
      when NImplementationStart then SImplementation.new(node)
      end
    end

    def create_parser
      PGlobal.new
    end

  end

  class SInterface < Scope

    def initialize start_node
      super()
      @start_node = start_node
    end

    def class_name
      @start_node.class_name
    end

    def ends_after? node
      NEnd === node
    end

    def create_parser
      PInterfaceHeader.new
    end

  end

  class SImplementation < Scope

    def initialize start_node
      super()
      @start_node = start_node
    end

    def class_name
      @start_node.class_name
    end

    def ends_after? node
      NEnd === node
    end

    def create_parser
      PInterfaceHeader.new
    end

  end

end
