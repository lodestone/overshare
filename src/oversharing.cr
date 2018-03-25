require "./oversharing/*"

module Oversharing
end

case ARGV[0]?
when "server"
  Kemal.run
when "debug"
  p Oversharing::Settings
end
