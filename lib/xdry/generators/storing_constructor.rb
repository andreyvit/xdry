
module XDry
module Generators

  class StoringConstructor < Generator
    id "store-ctor"

    def process_class oclass
      oclass.methods.each do |omethod|
        case omethod.selector
        when /^initWith/
          process_method oclass, omethod
        end
      end
    end

    def process_method oclass, omethod
      components = omethod.header_or_impl.selector_def.components
      mapping = {}
      components.each do |comp|
        kw = comp.keyword_without_colon
        oattr = oclass.find_attribute(kw)
        if oattr.nil? and comp == components.first
          stripped_kw = kw.gsub(/^initWith/, '')
          [stripped_kw.downcase, stripped_kw[0..0].downcase + stripped_kw[1..-1]].each do |alt_kw|
            oattr = oclass.find_attribute(alt_kw)
            break unless oattr.nil?
          end
        end
        mapping[kw] = oattr unless oattr.nil?
      end

      unless mapping.empty?
        new_selector_def = CompoundSelectorDef.new(components.collect do |comp|
          if oattr = mapping[kw = comp.keyword_without_colon]
            arg_name = comp.arg_name
            arg_name = oattr.name if arg_name.empty?
            SelectorComponent.new(comp.keyword, arg_name, comp.type || oattr.type)
          else
            comp
          end
        end)
        method_header = NMethodHeader.new(new_selector_def, omethod.ret_type)

        init_out = Emitter.new

        new_selector_def.components.each do |comp|
          if oattr = mapping[kw = comp.keyword_without_colon]
            field_name = oattr.field_name
            arg_name = comp.arg_name
            type = comp.type
            retain_policy = Boxing.retain_policy_of(type)

            retained = retain_policy.retain(arg_name)
            init_out << "#{field_name} = #{retained};"
          end
        end

        out << "#{method_header};"
        out.block "#{method_header}" do
          out.if "self = [super init]" do
            out << init_out
          end
          out << "return self;"
        end
      end
    end

  end

end
end
