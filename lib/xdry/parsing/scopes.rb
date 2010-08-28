
module XDry

  class SInterfaceFields < ChildScope

    parse_using PInterfaceFields

    on NInterfaceFieldsEnd, :pop

  end

  class SInterface < ChildScope

    parse_using PInterfaceHeader

    on NEnd, :pop
    on NOpeningBrace, :start => SInterfaceFields

    def class_name
      @start_node.class_name
    end

  end

  class SImplementation < ChildScope

    parse_using PInterfaceHeader

    on NEnd, :pop
    on NSynthesize, :add_to => :synthesizes

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
