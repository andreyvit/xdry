
module XDry

  class SMethodImpl < ChildScope

    parse_using PMethodImpl

    on NMethodEnd, :pop, :store_into => :end_node

    def selector
      @start_node.selector
    end

  end

  class SInterfaceFields < ChildScope

    parse_using PInterfaceFields

    on NInterfaceFieldsEnd, :pop, :store_into => :end_node

  end

  class SInterface < ChildScope

    parse_using PInterfaceHeader

    on NEnd, :pop
    on NOpeningBrace, :start => SInterfaceFields
    on SInterfaceFields, :store_into => :fields_scope

    def class_name
      @start_node.class_name
    end

  end

  class SImplementation < ChildScope

    parse_using PInterfaceHeader

    on NEnd, :pop
    on NSynthesize, :add_to => :synthesizes
    on NMethodStart, :start => SMethodImpl

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
