
module XDry
module Generators

  class FieldFromProperty < Generator
    id "field-from-prop"

    def process_attribute oclass, oattr
      unless oattr.has_field_def?
        if oattr.type_known?
          out << oattr.new_field_def.to_source
        end
      end
    end
  end

end
end
