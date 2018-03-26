module Overshare
  Settings = YAML.parse(File.open("config/settings.yml"))[ENV["ENV"]? || "development"]
end
