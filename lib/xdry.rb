
module XDry
  INDENT_STEP = "\t"  # FIXME: all usages of this should be changed to something smart
  FIELD_PREFIX = "_"  # FIXME: all usages of this should be changed to something smart
end

%w{
    support/string_additions support/symbol_additions support/enumerable_additions
    parsing/parts/var_types parsing/parts/selectors
    parsing/nodes parsing/model parsing/pos parsing/parsers
    parsing/scopes_support parsing/scopes
    parsing/scope_stack parsing/driver

    patching/emitter patching/patcher patching/insertion_points patching/item_patchers

    boxing generators_support run
  }.each { |name| require File.join(File.dirname(__FILE__), 'xdry', name) }
Dir[File.join(File.dirname(__FILE__), 'xdry', 'generators', '*.rb')].each { |f| require f }
