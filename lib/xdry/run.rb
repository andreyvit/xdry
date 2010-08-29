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

  def self.produce_everything out_file, oglobal, patcher, config
    puts "Generating code... " if config.verbose

    generators = Generators::ALL.collect { |klass| klass.new(config, patcher) }

    oglobal.classes.each do |oclass|
      puts "  - #{oclass.name}" if config.verbose

      if config.verbose
        oclass.attributes.each do |oattr|
          puts "      #{oattr}"
        end

        oclass.methods.each do |omethod|
          puts "      #{omethod}"
        end

        oclass.implementations.each do |nimpl|
          puts "      #{nimpl}"
          nimpl.synthesizes.each do |nsynth|
            puts "        #{nsynth}"
          end
        end
      end

      out = Emitter.new
      generators.each { |gen| gen.out = out }

      generators.each { |gen| gen.process_class(oclass) }

      oclass.attributes.each do |oattr|
        unless oattr.has_property_def?
          if oattr.type_known?
            pd = oattr.new_property_def
            out << pd.to_source
            # oattr.add_property_def! pd
          end
        end
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

  Config = Struct.new(:only, :dry_run, :watch, :verbose)

  def self.parse_command_line_config(args)
      config = Config.new
      config.only = nil
      config.dry_run = true
      config.watch = false
      config.verbose = false

      opts = OptionParser.new do |opts|
          opts.banner = "Usage: xdry [options]"

          opts.separator ""
          opts.separator "General options:"

          opts.on("-w", "--watch", "Watch for file system changes and rerun each time .h/.m is modified") do
            config.watch = true
          end

          opts.separator ""
          opts.separator "Filtering options:"

          opts.on("-o", "--only=MASK", "Only process files matching this mask") do |v|
              config.only = v
          end

          opts.separator ""
          opts.separator "Patching options:"

          opts.on("-R", "--real", "Really apply changes to your files (opposite of -n)") do |v|
            config.dry_run = false
          end
          opts.on("-n", "--dry-run", "Save changed files as .xdry.{h/m}. Default for now.") do |v|
            config.dry_run = true
          end

          opts.separator ""
          opts.separator "Common options:"

          opts.on("-v", "--verbose", "Print TONS of progress information") do
            config.verbose = true
          end

          opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit
          end
      end

      opts.parse!(args)
      return config
  end

  def self.run_once config
    oglobal = OGlobal.new

    Dir["**/*.m"].each do |m_file|
      next if config.only and not File.fnmatch(config.only, m_file)
      h_file = m_file.sub /\.m$/, '.h'
      if File.file? h_file
        puts h_file if config.verbose

        parser = ParsingDriver.new(oglobal)
        parser.verbose = config.verbose
        parser.parse_file(h_file)
        parser.parse_file(m_file)
      end
    end

    patcher = Patcher.new
    patcher.dry_run = config.dry_run
    patcher.verbose = config.verbose

    out_file_name = 'xdry.m'
    open(out_file_name, 'w') do |out_file|
      self.produce_everything(out_file, oglobal, patcher, config)
    end

    return patcher.save!
  end

  def self.test_run sources, verbose
    config = Config.new
    config.verbose = verbose

    oglobal = OGlobal.new

    parser = ParsingDriver.new(oglobal)
    parser.verbose = config.verbose
    sources.each do |file_path, content|
      parser.parse_string file_path, content
    end

    patcher = Patcher.new
    patcher.verbose = config.verbose

    out_file = StringIO.new
    self.produce_everything(out_file, oglobal, patcher, config)

    return patcher.retrieve!
  end

  def self.run args
    config = parse_command_line_config(args)

    run_once config

    if config.watch
      require 'rubygems'
      require 'fssm'
      rebuild = lambda do |base, relative|
        unless File.basename(relative) == 'xdry.m'
          changed_file_refs = run_once(config)
          unless changed_file_refs.empty?
            system "growlnotify", "-a", "Xcode", "-t", "XD.R.Y.", "-m", "Updating..."
            system "osascript", "-e", '
              tell application "Finder" to activate
              delay 0.3
              tell application "Xcode" to activate
              delay 0.5
              tell application "System Events" to keystroke "u" using {command down}
            '
            system "growlnotify", "-a", "Xcode", "-t", "XD.R.Y.", "-m", "Updated!"
          end
        end
      end
      puts
      puts "Monitoring for file system changes..."
      FSSM.monitor '.', ['**/*.{h,m}'] do |monitor|
        monitor.create &rebuild
        monitor.update &rebuild
        monitor.delete &rebuild
      end
    end
  end

end
