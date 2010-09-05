
module XDry
module Generators

  class DictionaryCoding < Generator
    id "dict-coding"

    def process_class oclass
      return unless oclass.attributes.any? { |a| a.persistent? }

      dictionary_var = "dictionary"

      defines_emitter = Emitter.new
      init_out        = Emitter.new
      repr_out        = Emitter.new

      dictionary_var = "dictionary"

      oclass.attributes.select { |a| a.persistent? }.each do |oattr|
        name, type = oattr.name, oattr.type
        field_name = oattr.field_name
        raw_name = "#{name}Raw"
        capitalized_name = case name
          when 'id', 'uid' then name.upcase
          else name[0..0].upcase + name[1..-1]
          end
        key_const = "#{capitalized_name}Key"

        type_boxer = Boxing.converter_for type
        if type_boxer.nil?
          raise StandardError, "Persistence not (yet) supported for type #{type}"
        end

        defines_emitter << %Q`\#define #{key_const} @"#{capitalized_name}"`

        init_out << %Q`id #{raw_name} = [#{dictionary_var} objectForKey:#{key_const}];`
        init_out.if "#{raw_name} != nil" do
          unboxed = type_boxer.unbox_retained(init_out, raw_name, name)
          init_out << "#{field_name} = #{unboxed};"
        end

        boxed = type_boxer.box(repr_out, field_name, name)
        repr_out << %Q`[dictionary setObject:#{boxed} forKey:#{key_const}];`
      end

      init_code = Emitter.capture do |o|
        o.method "(id)initWithDictionary:(NSDictionary *)#{dictionary_var}" do
          o.if "self = [super init]" do
          end
          o << "return self;"
        end
      end

      repr_code = Emitter.capture do |o|
        o.method "(NSDictionary *)dictionaryRepresentation" do
          o << "NSMutableDictionary *#{dictionary_var} = [NSMutableDictionary dictionary];"
          o << "return #{dictionary_var};"
        end
      end

      file_scope = oclass.main_implementation.parent_scope
      define_ip = MultiIP.new(AfterDefineIP.new(file_scope), BeforeImplementationStartIP.new(oclass))
      define_lines = Emitter.capture do |o|
        each_persistent_attr(oclass) do |oattr, capitalized_name, key_const, type_boxer|
          unless file_scope.children.any? { |n| NDefine === n && n.word == key_const }
            o << %Q`\#define #{key_const} @"#{capitalized_name}"`
          end
        end
      end
      define_ip.wrap_with_empty_lines_if_last!
      define_ip.insert @patcher, define_lines

      MethodPatcher.new(patcher, oclass, 'dictionaryRepresentation', ImplementationStartIP.new(oclass), repr_code) do |omethod|
        impl = omethod.impl
        ip = BeforeReturnIP.new(impl)

        lines = Emitter.capture do |o|
          each_persistent_attr(oclass) do |oattr, capitalized_name, key_const, type_boxer|
            unless impl.children.any? { |n| NLine === n && n.line =~ /\bsetObject:.*(?:\b#{oattr.name}|\b#{oattr.field_name}\b)/ }
              boxed = type_boxer.box(o, oattr.field_name, oattr.name)
              o << %Q`[dictionary setObject:#{boxed} forKey:#{key_const}];`
            end
          end
        end

        ip.insert @patcher, lines unless lines.empty?
      end

      MethodPatcher.new(patcher, oclass, 'initWithDictionary:', ImplementationStartIP.new(oclass), init_code) do |omethod|
        impl = omethod.impl
        ip = InsideConstructorIfSuperIP.new(impl)
        var_name = impl.start_node.selector_def.var_name_after_keyword('initWithDictionary:')

        lines = Emitter.capture do |o|
          each_persistent_attr(oclass) do |oattr, capitalized_name, key_const, type_boxer|
            unless impl.children.any? { |n| NLine === n && n.line =~ /^(?:self\s*.\s*#{oattr.name}|#{oattr.field_name})\s*=/ }
              raw_name = "#{oattr.name}Raw"
              o << %Q`id #{raw_name} = [#{var_name} objectForKey:#{key_const}];`
              o.if "#{raw_name} != nil" do
                unboxed = type_boxer.unbox_retained(o, raw_name, oattr.name)
                o << "#{oattr.field_name} = #{unboxed};"
              end
            end
          end
        end

        ip.insert @patcher, lines unless lines.empty?
      end
    end

    def each_persistent_attr oclass
      oclass.attributes.select { |a| a.persistent? }.each do |oattr|
        name, type = oattr.name, oattr.type
        field_name = oattr.field_name
        capitalized_name = case name
          when 'id', 'uid' then name.upcase
          else name[0..0].upcase + name[1..-1]
          end
        key_const = "#{capitalized_name}Key"

        type_boxer = Boxing.converter_for type
        if type_boxer.nil?
          raise StandardError, "Persistence not (yet) supported for type #{type}"
        end

        yield oattr, capitalized_name, key_const, type_boxer
      end
    end

  end

end
end
