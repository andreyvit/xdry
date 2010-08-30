
module XDry
module Generators

  class FieldFromProperty < Generator
    id "field-from-prop"

    def process_attribute oclass, oattr
      if !oattr.has_field_def? && oattr.type_known? && !oclass.has_method_impl?(oattr.getter_selector)
        lines = [oattr.new_field_def.to_source]
        if oclass.main_interface # && oclass.main_interface.fields_scope
          node = oclass.main_interface.fields_scope.end_node
          patcher.insert_before node.pos, lines, node.indent + INDENT_STEP
        end
      end
    end
  end

end
end
