require "./overshare/*"

module Overshare
end

case ARGV[0]?
when "server"
  Kemal.run
when "settings"
  p Overshare::Settings
when "+"
  puts "TODO: Add file or url"
  # TODO: ~/.config/overshare/settings.yml
  # TODO: overshare + path/to/file.txt
  # TODO: overshare + https://fonts.google.com
end
