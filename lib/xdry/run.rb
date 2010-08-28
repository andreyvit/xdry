require 'optparse'

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

  def self.add_dealloc out, oclass
    dealloc_out = Emitter.new

    oclass.attributes.each do |oattr|
      next unless oattr.has_field_def?

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

  def self.produce_everything out_file, oglobal, patcher
    puts "Generating code... "
    oglobal.classes.each do |oclass|
      puts "  - #{oclass.name}"

      out = Emitter.new

      if DEBUG
        oclass.attributes.each do |oattr|
          puts "      #{oattr}"
        end

        oclass.methods.each do |omethod|
          puts "      #{omethod}" if DEBUG
        end

        oclass.implementations.each do |nimpl|
          puts "      #{nimpl}"
          nimpl.synthesizes.each do |nsynth|
            puts "        #{nsynth}"
          end
        end
      end

      synthesize_out = Emitter.new
      oclass.attributes.each do |oattr|
        unless oattr.has_field_def?
          out << oattr.new_field_def.to_source
          oattr.add_field_def! oattr.new_field_def
        end
        unless oattr.has_property_def?
          out << oattr.new_property_def.to_source
        end
        if oattr.has_property_def?
          unless oattr.has_synthesize?
            synthesize = oattr.new_synthesize
            impl = oclass.main_implementation
            pos = if impl.synthesizes.empty?
              impl.start_node.pos
            else
              impl.synthesizes.sort { |a, b| a.pos.line_no <=> b.pos.line_no }.last.pos
            end
            patcher.insert_after pos, [synthesize.to_s]
          end
        end
        synthesize_out << "@synthesize #{oattr.name}=#{oattr.field_name};"
      end

      out << synthesize_out

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
        out_file.puts
        out_file.puts
        out_file.puts "/" * 79
        out_file.puts "@implementation #{oclass.name}"
        out_file.puts
        out_file.puts out.to_s
        out_file.puts
        out_file.puts "@end"
      end
    end
  end

  Config = Struct.new(:only)

  def self.parse_command_line_config(args)
      config = Config.new
      config.only = nil

      opts = OptionParser.new do |opts|
          opts.banner = "Usage: xdry [options]"

          opts.separator ""
          opts.separator "Filtering options:"

          opts.on("-o", "--only=MASK", "Only process files matching this mask") do |v|
              config.only = v
          end

          opts.separator ""
          opts.separator "Common options:"

          opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit
          end
      end

      opts.parse!(args)
      return config
  end

  def self.run args
    config = parse_command_line_config(args)

    oglobal = OGlobal.new

    Dir["**/*.m"].each do |m_file|
      next if config.only and not File.fnmatch(config.only, m_file)
      h_file = m_file.sub /\.m$/, '.h'
      if File.file? h_file
        puts h_file if DEBUG

        parser = ParsingDriver.new(oglobal)
        parser.parse_file(h_file)
        parser.parse_file(m_file)
      end
    end

    patcher = Patcher.new

    out_file_name = 'xdry.m'
    open(out_file_name, 'w') do |out_file|
      self.produce_everything(out_file, oglobal, patcher)
    end

    patcher.save!
    puts "See #{out_file_name}."
  end

end
