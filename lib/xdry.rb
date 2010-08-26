
module XDry
  DEBUG = false
end

%w/fragments model parser states boxing emitter run/.
  each { |name| require File.join(File.dirname(__FILE__), 'xdry', name) }
