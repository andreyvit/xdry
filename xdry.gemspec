# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xdry}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andrey Tarantsov"]
  s.date = %q{2011-03-22}
  s.default_executable = %q{xdry}
  s.description = %q{Autogenerates all kinds of funky stuff (like accessors) in Xcode projects}
  s.email = %q{andreyvit@gmail.com}
  s.executables = ["xdry"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/xdry",
    "lib/xdry.rb",
    "lib/xdry/boxing.rb",
    "lib/xdry/generators/ctor_from_field.rb",
    "lib/xdry/generators/dealloc.rb",
    "lib/xdry/generators/dictionary_coding.rb",
    "lib/xdry/generators/field_from_property.rb",
    "lib/xdry/generators/property-from-field.rb",
    "lib/xdry/generators/storing_constructor.rb",
    "lib/xdry/generators/synthesize.rb",
    "lib/xdry/generators_support.rb",
    "lib/xdry/parsing/driver.rb",
    "lib/xdry/parsing/model.rb",
    "lib/xdry/parsing/nodes.rb",
    "lib/xdry/parsing/parsers.rb",
    "lib/xdry/parsing/parts/selectors.rb",
    "lib/xdry/parsing/parts/var_types.rb",
    "lib/xdry/parsing/pos.rb",
    "lib/xdry/parsing/scope_stack.rb",
    "lib/xdry/parsing/scopes.rb",
    "lib/xdry/parsing/scopes_support.rb",
    "lib/xdry/patching/emitter.rb",
    "lib/xdry/patching/insertion_points.rb",
    "lib/xdry/patching/item_patchers.rb",
    "lib/xdry/patching/patcher.rb",
    "lib/xdry/run.rb",
    "lib/xdry/support/enumerable_additions.rb",
    "lib/xdry/support/string_additions.rb",
    "lib/xdry/support/symbol_additions.rb",
    "site/_config.yml",
    "site/_example",
    "site/_layouts/default.html",
    "site/_plugins/example.rb",
    "site/_plugins/highlight_unindent.rb",
    "site/index.md",
    "site/master.css",
    "spec/boxing_spec.rb",
    "spec/ctor_from_field_spec.rb",
    "spec/dealloc_spec.rb",
    "spec/dictionary_coding_spec.rb",
    "spec/field_from_prop_spec.rb",
    "spec/prop_from_field_spec.rb",
    "spec/readme_samples_spec.rb",
    "spec/selector_parsing_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/synthesize_spec.rb",
    "spec/unknown_stuff_handling_spec.rb",
    "spec/vartype_parsing_spec.rb",
    "xdry.gemspec"
  ]
  s.homepage = %q{http://andreyvit.github.com/xdry/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{eXtra D.R.Y. for Xcode}
  s.test_files = [
    "spec/boxing_spec.rb",
    "spec/ctor_from_field_spec.rb",
    "spec/dealloc_spec.rb",
    "spec/dictionary_coding_spec.rb",
    "spec/field_from_prop_spec.rb",
    "spec/prop_from_field_spec.rb",
    "spec/readme_samples_spec.rb",
    "spec/selector_parsing_spec.rb",
    "spec/spec_helper.rb",
    "spec/synthesize_spec.rb",
    "spec/unknown_stuff_handling_spec.rb",
    "spec/vartype_parsing_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

