require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "xdry"
    gem.summary = %Q{eXtra D.R.Y. for Xcode}
    gem.description = %Q{
        Autogenerates all kinds of funky stuff (like accessors) in Xcode projects
    }.strip
    gem.email = "andreyvit@gmail.com"
    gem.homepage = "http://github.com/mockko/xdry"
    gem.authors = ["Andrey Tarantsov"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # http://www.rubygems.org/read/chapter/20
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec
