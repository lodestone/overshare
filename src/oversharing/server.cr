ENV["ENV"] = "development"
require "remarkdown"
require "kemal"
require "./details"
require "./settings"

post "/+" do |env|
  if url = env.params.body["url"]?
    detail = Oversharing::Detail.make(url)
    {"result" => "OK", "uri" => detail.sid}.to_json
  elsif file = env.params.files["file"]?
    filename = file.filename
    FileUtils.mv file.tmpfile.path, "/tmp/#{filename}"
    detail = Oversharing::Detail.make("/tmp/#{filename}")
    {"result" => "OK", "uri" => detail.sid}.to_json
  else
    {"error" => "must include <file> or <url> parameter"}.to_json
  end
end

get "/+*sid" do |env|
  sid = env.params.url["sid"]
  detail = Oversharing::Detail.get(sid)
  if detail.file?
    # send_file env, detail.endpoint_path, Kemal::Utils.mime_type(detail.endpoint_path)
    env.redirect "/=#{detail.endpoint_path.gsub("details/","")}"
  else
    env.redirect detail.endpoint
  end
end

get "/=*path" do |env|
  path = env.params.url["path"]
  send_file env, "details/#{path}"
end

get "/~*sid" do |env|
  sid = env.params.url["sid"]
  detail = Oversharing::Detail.get(sid)
  p detail
  if detail.endpoint_path[/\.md$/]
    html = Remarkdown.to_html File.read(detail.endpoint_path)
    render "static/html.ecr"
  else
    env.redirect "/=#{detail.endpoint_path.gsub("details/","")}"
  end
end
