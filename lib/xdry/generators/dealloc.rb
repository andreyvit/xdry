
module XDry
module Generators

  class Dealloc < Generator
    id "dealloc"

    def process_class oclass
      dealloc_out = Emitter.new

      oclass.attributes.each do |oattr|
        next if not oattr.has_field_def?

        field_name = oattr.field_name
        retain_policy = Boxing.retain_policy_of(oattr.type)

        retain_policy.release_and_clear dealloc_out, field_name
      end

      unless dealloc_out.empty?
        dealloc_method = oclass.find_method('dealloc')
        if dealloc_method && dealloc_method.has_impl?
          impl = dealloc_method.impl
          ending_node = impl.children.find { |child| child.is_a? NSuperCall }
          if ending_node.nil?
            ending_node = impl.end_node
            indent = ending_node.indent + INDENT_STEP
          else
            indent = ending_node.indent
          end
          lines = dealloc_out.lines.collect { |l| indent + l }
          @patcher.insert_before ending_node.pos, lines
        else
          out.method "(void)dealloc" do
            out << dealloc_out
            out << "[super dealloc];"
          end
        end
      end
    end
  end

end
end
