require "./overshare/*"

module Overshare
  CODE_LANGS = %w[
    applescript
    bib
    c
    coffee
    cpp
    cr
    css
    csv
    cxx
    diff
    erb
    feature
    haml
    java
    js
    json
    py
    r
    rb
    sass
    scss
    sh
    sql
    tex
    toml
    ts
    txt
    vim
    vue
    xml
    yaml
    yml
  ]
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
