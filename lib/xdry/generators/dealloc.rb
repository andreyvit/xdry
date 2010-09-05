
module XDry
module Generators

  DEALLOC_CODE = [
    "",
    "- (void)dealloc {",
    "\t[super dealloc];",
    "}",
    "",
  ]

  class Dealloc < Generator
    id "dealloc"

    def process_class oclass

      MethodPatcher.new(patcher, oclass, 'dealloc', ImplementationStartIP.new(oclass), DEALLOC_CODE) do |dealloc_method|
        impl = dealloc_method.impl
        ip = BeforeSuperCallIP.new(impl)

        existing_releases = impl.children.select { |child| child.is_a? NReleaseCall }
        lines = generate_release_calls_if(oclass) do |oattr|
          !existing_releases.any? { |n| n.expr == oattr.field_name || n.expr == "self.#{oattr.name}" }
        end

        ip.insert @patcher, lines unless lines.empty?
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
