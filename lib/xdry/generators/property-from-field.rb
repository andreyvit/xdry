
module XDry
module Generators

  class PropertyFromField < Generator
    id "prop-from-field"

    def process_attribute oclass, oattr
      unless oattr.has_property_def?
        if oattr.type_known?
          pd = oattr.new_property_def
          out << pd.to_source
        end
      end
    end
  end

end
end
