
module XDry
module Generators

  class PropertyFromField < Generator
    id "prop-from-field"

    def process_attribute oclass, oattr
      if !oattr.has_property_def? && oattr.wants_property? && oattr.type_known?
        pd = oattr.new_property_def

        ip = BeforeInterfaceEndIP.new(oclass)
        lines = Emitter.capture do |o|
          o << pd.to_source
        end
        ip.insert patcher, [""] + lines + [""]
      end
    end
  end

end
end
