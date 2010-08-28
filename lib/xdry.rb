
module XDry
  DEBUG = true
end

%w{
    parsing/parts/var_types parsing/parts/selectors
    parsing/nodes parsing/model parsing/pos parsing/parsers parsing/scopes
    parsing/scope_stack parsing/driver

    patching/emitter patching/patcher

    boxing run
  }.each { |name| require File.join(File.dirname(__FILE__), 'xdry', name) }
