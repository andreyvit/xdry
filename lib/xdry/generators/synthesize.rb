
module XDry
module Generators

  class Synthesize < Generator
    id "synth"

    def process_attribute oclass, oattr
      if oattr.has_property_def? && !oattr.has_synthesize? && !oclass.has_method_impl?(oattr.getter_selector)
        synthesize = oattr.new_synthesize
        impl = oclass.main_implementation
        new_lines = [synthesize.to_s]
        if impl.synthesizes.empty?
          pos = impl.start_node.pos
          new_lines = [""] + new_lines + [""]
        else
          pos = impl.synthesizes.sort { |a, b| a.pos.line_no <=> b.pos.line_no }.last.pos
        end
        patcher.insert_after pos, new_lines
      end
    end
  end

end
end
