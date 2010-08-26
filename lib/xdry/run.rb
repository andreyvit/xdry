module XDry

  def self.add_persistence out, oclass
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

  def self.add_initializing_constructor out, oclass, omethod
    components = omethod.header.selector_def.components
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
      new_selector_def = OCompoundSelectorDef.new(components.collect do |comp|
        if oattr = mapping[kw = comp.keyword_without_colon]
          arg_name = comp.arg_name
          arg_name = oattr.name if arg_name.empty?
          OSelectorComponent.new(comp.keyword, arg_name, comp.type || oattr.type)
        else
          comp
        end
      end)
      method_header = OMethodHeader.new(new_selector_def, omethod.ret_type)

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

  def self.add_dealloc out, oclass
    dealloc_out = Emitter.new

    oclass.attributes.each do |oattr|
      next unless oattr.has_field_def?

      field_name = oattr.field_name
      retain_policy = Boxing.retain_policy_of(oattr.type)

      retain_policy.release_and_clear dealloc_out, field_name
    end

    unless dealloc_out.empty?
      out.method "(id)dealloc" do
        out << dealloc_out
        out << "[super dealloc];"
      end
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
        # parser.parse_header(m_file)
      end
    end

    puts
    oglobal.classes.each do |oclass|
      puts
      puts "#{oclass}"

      out = Emitter.new

      oclass.attributes.each do |oattr|
        puts "  #{oattr}"
        unless oattr.has_field_def?
          out << oattr.new_field_def.to_source
        end
        unless oattr.has_property_def?
          out << oattr.new_property_def.to_source
        end
      end

      oclass.methods.each do |omethod|
        puts "  #{omethod}"
      end

      if oclass.attributes.any? { |a| a.persistent? }
        add_persistence out, oclass
      end

      oclass.methods.each do |omethod|
        case omethod.selector
        when /^initWith/
          add_initializing_constructor out, oclass, omethod
        end
      end

      add_dealloc out, oclass

      unless out.empty?
        puts
        puts out.to_s
      end
    end
  end

end
