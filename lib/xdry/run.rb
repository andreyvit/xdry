require 'optparse'

module XDry

  def self.produce_everything out_file, oglobal, patcher, config
    puts "Generating code... " if config.verbose

    generators = Generators::ALL.select { |klass| config.enabled?(klass.id) }.
        collect { |klass| klass.new(config, patcher) }

    if config.verbose
      puts "Running generators: " + generators.collect { |gen| gen.class.id }.join(", ")
    end

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

  class Config < Struct.new(:only, :dry_run, :watch, :verbose, :disable, :enable_only)

    def initialize
      self.only = nil
      self.dry_run = true
      self.watch = false
      self.verbose = false
      self.disable = []
      self.enable_only = nil
    end

    def enabled? gen_id
      (enable_only.nil? || enable_only.include?(gen_id)) && !disable.include?(gen_id)
    end

  end

  def self.parse_command_line_config(args)
      config = Config.new

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
          opts.separator "Choosing which generators to run:"

          opts.on("-e", "--enable-only=LIST", "Only run the given generators (e.g.: -e dealloc,synth)") do |v|
            config.enable_only = v.split(",").collect { |n| n.strip }

            all = XDry::Generators::ALL.collect { |kl| kl.id }
            unless (unsup = config.enable_only - all).empty?
              puts "Unknown generator names in -e: #{unsup.join(', ')}."
              puts "Supported names are: #{all.join(', ')}."
              exit 1
            end
          end

          opts.on("-d", "--disable=LIST", "Disable the given generators (e.g.: -d dealloc,synth)") do |v|
            config.disable = v.split(",").collect { |n| n.strip }

            all = XDry::Generators::ALL.collect { |kl| kl.id }
            unless (unsup = config.disable - all).empty?
              puts "Unknown generator names in -d: #{unsup.join(', ')}."
              puts "Supported names are: #{all.join(', ')}."
              exit 1
            end
          end

          opts.on("--list", "List all supported generators and exit") do |v|
            XDry::Generators::ALL.each { |kl| puts "#{kl.id}" }
            exit
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

  def self.test_run sources, config
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
