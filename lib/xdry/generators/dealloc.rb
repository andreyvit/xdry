
module XDry
module Generators

  class Dealloc < Generator
    id "dealloc"

    def process_class oclass

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

        existing_releases = impl.children.select { |child| child.is_a? NReleaseCall }
        lines = generate_release_calls_if(oclass) do |oattr|
          !existing_releases.any? { |n| n.expr == oattr.field_name || n.expr == "self.#{oattr.name}" }
        end
        lines = lines.collect { |l| indent + l }

        @patcher.insert_before ending_node.pos, lines unless lines.empty?
      else
        lines = generate_release_calls_if(oclass) { true }
        unless lines.empty?
          out.method "(void)dealloc" do
            out << lines
            out << "[super dealloc];"
          end
        end
      end
    end

  private

    def generate_release_calls_if oclass
      dealloc_out = Emitter.new

      oclass.attributes.each do |oattr|
        next if not oattr.has_field_def?

        field_name = oattr.field_name
        retain_policy = Boxing.retain_policy_of(oattr.type)

        if yield(oattr)
          retain_policy.release_and_clear dealloc_out, field_name
        end
      end

      dealloc_out.lines
    end

  end

end
end
