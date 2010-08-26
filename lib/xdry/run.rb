module XDry

  def self.add_persistence out, oclass
    dictionary_var = "dictionary"
    out.method "(id) initWithDictionary:(NSDictionary *)#{dictionary_var}" do
      out.if "self = [super init]" do

        oclass.attributes.select { |a| a.persistent? }.each do |oattr|
          name, type = oattr.name, oattr.type
          field_name = oattr.field_name
          raw_name = "#{name}Raw"

          type_boxer = Boxing.converter_for type
          if type_boxer.nil?
            raise StandardError, "Persistence not (yet) supported for type #{type}"
          end

          out << %Q`id #{raw_name} = [#{dictionary_var} objectForKey:@"#{name}"];`
          out.if "#{raw_name} != nil" do
            unboxed = type_boxer.unbox_retained(out, raw_name)
            out << "#{field_name} = #{unboxed};"
          end
        end

      end
      out << "return self;"
    end

    out.method "(NSDictionary *) dictionaryRepresentation" do
      dictionary_var = "dictionary"
      out << "NSMutableDictionary *#{dictionary_var} = [NSMutableDictionary dictionary];"

      oclass.attributes.select { |a| a.persistent? }.each do |oattr|
        name, type = oattr.name, oattr.type
        field_name = oattr.field_name
        raw_name = "#{name}Raw"

        type_boxer = Boxing.converter_for type
        if type_boxer.nil?
          raise StandardError, "Persistence not (yet) supported for type #{type}"
        end

        boxed = type_boxer.box(out, field_name)
        out << %Q`[dictionary setObject:#{boxed} forKey:@"#{name}"];`
      end

      out << "return #{dictionary_var};"
    end
  end

  def self.run
    oglobal = OGlobal.new

    Dir["**/*.m"].each do |m_file|
      h_file = m_file.sub /\.m$/, '.h'
      if File.file? h_file
        puts h_file

        parser = Parser.new(oglobal)
        parser.parse_header(h_file)
        parser.parse_header(m_file)
      end
    end

    puts
    oglobal.classes.each do |oclass|
      puts
      puts "#{oclass}"

      out = Emitter.new

      oclass.attributes.each do |oattr|
        unless oattr.has_field_def?
          out << oattr.new_field_def.to_source
        end
        unless oattr.has_property_def?
          out << oattr.new_property_def.to_source
        end
      end

      if oclass.attributes.any? { |a| a.persistent? }
        add_persistence out, oclass
      end

      unless out.empty?
        puts
        puts out.to_s
      end
    end
  end

end
