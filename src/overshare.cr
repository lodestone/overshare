require "./overshare/*"

module Overshare
end

case ARGV[0]?
when "server"
  Kemal.run
when "settings"
  p Overshare::Settings
end
