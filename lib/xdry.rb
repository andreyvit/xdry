
module XDry
end

%w{
    support/string_additions support/symbol_additions support/enumerable_additions
    parsing/parts/var_types parsing/parts/selectors
    parsing/nodes parsing/model parsing/pos parsing/parsers
    parsing/scopes_support parsing/scopes
    parsing/scope_stack parsing/driver

    patching/emitter patching/patcher

    boxing run
  }.each { |name| require File.join(File.dirname(__FILE__), 'xdry', name) }
