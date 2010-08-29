require 'optparse'

module XDry

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
