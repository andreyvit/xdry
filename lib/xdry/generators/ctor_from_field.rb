
module XDry
module Generators

  class ConstructorFromField < Generator
    id "ctor-from-field"

    def process_class oclass
      attributes = oclass.attributes.select { |a| a.wants_constructor? }
      return if attributes.empty?

      patch_implementation! oclass, attributes
      patch_interface! oclass, attributes
    end

    def patch_implementation! oclass, attributes
      impl_selector_def = impl_selector_def_for(attributes)

      init_code = Emitter.capture do |o|
        o.method "(id)#{impl_selector_def}" do
          o.if "self = [super init]" do
          end
          o << "return self;"
        end
      end

      MethodPatcher.new(patcher, oclass, impl_selector_def.selector, ImplementationStartIP.new(oclass), init_code) do |omethod|
        impl = omethod.impl
        ip = InsideConstructorIfSuperIP.new(impl)

        lines = Emitter.capture do |o|
          attributes.zip(impl_selector_def.components).each do |oattr, selector_component|
            name, type = oattr.name, oattr.type
            capitalized_name = name.capitalized_identifier

            retain_policy = Boxing.retain_policy_of type

            unless impl.children.any? { |n| NLine === n && n.line =~ /^(?:self\s*.\s*#{oattr.name}|#{oattr.field_name})\s*=/ }

              var_name = impl.start_node.selector_def.var_name_after_keyword(selector_component.keyword)

              field_ref = oattr.field_name
              field_ref = "self->#{field_ref}" if field_ref == var_name

              retained = retain_policy.retain(var_name)
              o << "#{field_ref} = #{retained};"
            end
          end
        end

        ip.insert @patcher, lines unless lines.empty?
      end
    end

    def patch_interface! oclass, attributes
      intf_selector_def = intf_selector_def_for(attributes)

      omethod = oclass.find_method(intf_selector_def.selector)
      unless omethod && omethod.has_header?

        ip = BeforeInterfaceEndIP.new(oclass)
        lines = Emitter.capture do |o|
          o << "- (id)#{intf_selector_def};"
        end
        ip.insert patcher, [""] + lines + [""]

      end
    end

    def impl_selector_def_for attributes
      CompoundSelectorDef.new(attributes.each_with_index.collect { |a, i| selector_component_for(a, i, true) })
    end

    def intf_selector_def_for attributes
      CompoundSelectorDef.new(attributes.each_with_index.collect { |a, i| selector_component_for(a, i, false) })
    end

    def selector_component_for attribute, index, is_impl
      keyword = attribute.name
      keyword = "initWith#{keyword.capitalized_identifier}" if index == 0

      arg_name = attribute.name
      arg_name = arg_name.prefixed_as_arg_name if is_impl && arg_name == attribute.field_name

      SelectorComponent.new("#{keyword}:", arg_name, attribute.type)
    end

  end

end
end
