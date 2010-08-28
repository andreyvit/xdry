
module XDry

  class SInterface < ChildScope

    parse_using PInterfaceHeader

    on NEnd, :pop

    def class_name
      @start_node.class_name
    end

  end

  class SImplementation < ChildScope

    parse_using PInterfaceHeader

    on NEnd, :pop

    def class_name
      @start_node.class_name
    end

  end

  class SFile < Scope

    parse_using PGlobal

    on NInterfaceStart, :start => SInterface
    on NImplementationStart, :start => SImplementation

  end

end
