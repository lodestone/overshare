module Oversharing
  Settings = YAML.parse(File.open("config/settings.yml"))[ENV["ENV"]]
end
