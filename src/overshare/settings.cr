module Overshare
  Settings = YAML.parse(File.open("config/settings.yml"))[ENV["KEMAL_ENV"]? || "development"]
end
