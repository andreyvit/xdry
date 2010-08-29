$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'xdry'
require 'spec'
require 'spec/autorun'

def xdry content
  verbose = ((ENV['VERBOSE'] || '0').to_i != 0)

  first_line_indent = content.split("\n", 2).first.gsub(/\S.*$/, '')
  deleted_indent    = first_line_indent.sub(/\s\s$/, '-( |$)')
  added_indent      = first_line_indent.sub(/\s\s$/, "\\\\+( |$)")

  orig_content = content.lines.select { |l| l =~ /^(#{first_line_indent}|#{deleted_indent})|^$/ }.join("")
  new_content  = content.lines.select { |l| l =~ /^(#{first_line_indent}|#{added_indent})|^$/ }.join("")

  orig_content = orig_content.gsub(/^(#{first_line_indent}|#{deleted_indent})/, '')
  new_content  = new_content.gsub(/^(#{first_line_indent}|#{added_indent})/, '')

  if verbose
    puts "-" * 40
    puts orig_content
    puts "-" * 40
    puts new_content
    puts "-" * 40
  end

  result = XDry.test_run({'main.m' => orig_content}, verbose)['main.m']
  result = orig_content if result.nil?

  result.should == new_content
end

Spec::Runner.configure do |config|

end
