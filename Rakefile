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

namespace :site do
  desc "Regenerate the site using Jekyll"
  task :build do
    Dir.chdir 'site' do
      system "jekyll"
    end
  end

  desc "Open a generated site in a web browser"
  task :open => [:build] do
    system "open site/_site/index.html"
  end

  desc "Regenerate the site and update gh-pages branch"
  task :update => [:build] do
    mods = `git status --porcelain --untracked-files=no`
    if mods.strip.size > 0
      system "git status --short --untracked-files=no"
      puts
      puts "** There are uncommitted changes. Please commit or stash them before updating the site."
      exit
    end

    source_commit = `git rev-parse HEAD`.strip

    ENV['GIT_INDEX_FILE'] = File.expand_path('.git/index-gh-pages')
    ENV['GIT_WORK_TREE'] = File.expand_path('site/_site')
    ENV['GIT_DIR'] = File.expand_path('.git')
    Dir.chdir 'site/_site' do
      system "git update-index --add --remove #{Dir["**/*"].join(' ')}"
      tree=`git write-tree`.strip
      puts "Tree = #{tree}"
      parent=`git rev-parse refs/heads/gh-pages`.strip
      puts "Parent = #{parent}"
      commit=`echo "Generate the site from source repository commit #{source_commit}" | git commit-tree #{tree} -p #{parent}`.strip
      puts "Commit = #{commit}"
      system "git update-ref -m 'Generate the site from source repository commit #{source_commit}' refs/heads/gh-pages #{commit}"
    end
  end

  desc "Push an updated site to GitHub"
  task :push do
    system "git push origin gh-pages"
  end

end
