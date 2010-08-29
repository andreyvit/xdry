
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
        out.method "(void)dealloc" do
          out << dealloc_out
          out << "[super dealloc];"
        end
      end
    end
  end

end
end
