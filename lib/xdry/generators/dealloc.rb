
module XDry
module Generators

  class DeallocMethodPatcher < MethodPatcher

    def find
      find_method_impl_by_selector('dealloc')
    end

    def empty_implementation
      [
        "",
        "- (void)dealloc {",
        "\t[super dealloc];",
        "}",
        "",
      ]
    end

    def insertion_point
      ImplementationStartIP.new(oclass)
    end

  end

  class Dealloc < Generator
    id "dealloc"

    def process_class oclass

      DeallocMethodPatcher.new(oclass, patcher) do |dealloc_method|
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
