
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

      out << defines_emitter

      out.method "(id) initWithDictionary:(NSDictionary *)#{dictionary_var}" do
        out.if "self = [super init]" do
          out << init_out
        end
        out << "return self;"
      end

      out.method "(NSDictionary *) dictionaryRepresentation" do
        out << "NSMutableDictionary *#{dictionary_var} = [NSMutableDictionary dictionary];"
        out << repr_out
        out << "return #{dictionary_var};"
      end
    end

  end

end
end
