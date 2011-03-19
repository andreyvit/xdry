$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'xdry'
require 'rspec'
require 'rspec/autorun'

def remove_common_indent content
  first_line_indent = content.split("\n", 2).first.gsub(/\S.*$/, '')
  content.gsub(/^#{first_line_indent}/, '')
end

def xdry gens, content=nil
  if content.nil?
    content = gens
    gens = nil
  end

  config = XDry::Config.new
  config.verbose = ((ENV['VERBOSE'] || '0').to_i != 0)

  unless gens.nil?
    gens = [gens] if gens.is_a?(Symbol)
    config.enable_only = gens.collect { |g| g.to_s.gsub('_', '-') }
  end

  first_line_indent = content.split("\n", 2).first.gsub(/\S.*$/, '')
  deleted_indent    = first_line_indent.sub(/\s\s$/, '-( |$)')
  added_indent      = first_line_indent.sub(/\s\s$/, "\\\\+( |$)")

  orig_content = content.lines.select { |l| l =~ /^(#{first_line_indent}|#{deleted_indent})|^$/ }.join("")
  new_content  = content.lines.select { |l| l =~ /^(#{first_line_indent}|#{added_indent})|^$/ }.join("")

  orig_content = orig_content.gsub(/^(#{first_line_indent}|#{deleted_indent})/, '')
  new_content  = new_content.gsub(/^(#{first_line_indent}|#{added_indent})/, '')

  if config.verbose
    puts "-" * 40
    puts orig_content
    puts "-" * 40
    puts new_content
    puts "-" * 40
  end

  result = XDry.test_run({'main.m' => orig_content}, config)['main.m']
  result = orig_content if result.nil?
  result = result.gsub("\t", "  ")  # tests use 2 spaces for indentation

  result.should == new_content
end

RSpec.configure do |config|

end
