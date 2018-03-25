ENV["ENV"] = "development"
require "remarkdown"
require "kemal"
require "./details"
require "./settings"

# TODO: Get rid of all these conditionals

post "/+" do |env|
  if url = env.params.body["url"]?
    detail = Overshare::Detail.make(url)
    {"result" => "OK", "uri" => detail.uri}.to_json
  elsif file = env.params.files["file"]?
    filename = file.filename
    FileUtils.mv file.tmpfile.path, "/tmp/#{filename}"
    detail = Overshare::Detail.make("/tmp/#{filename}")
    {"result" => "OK", "uri" => detail.uri}.to_json
  else
    {"error" => "must include <file> or <url> parameter"}.to_json
  end
end

get "/+*sid" do |env|
  sid = env.params.url["sid"]
  detail = Overshare::Detail.get(sid)
  if detail.file?
    env.redirect "/=#{detail.endpoint_path.gsub("details/","")}"
  else
    env.redirect detail.endpoint
  end
end

get "/=*sid" do |env|
  if sid = env.params.url["sid"]?
    send_file env, "details/#{sid}"
  else
    env.response.status_code = 404
    {"error" => "must include <file> or <url> parameter"}.to_json
  end
end

get "/~*sid" do |env|
  if sid = env.params.url["sid"]?
    detail = Overshare::Detail.get(sid)
    if detail.endpoint_path =~ /\.md$/
      html = Remarkdown.to_html File.read(detail.endpoint_path)
      render "templates/html.ecr"
    elsif detail.endpoint_path =~ /\.adoc$/
      html = `asciidoctor -o - #{detail.endpoint_path}`
      render "templates/html.ecr"
    else
      env.redirect "/=#{detail.sid}/#{detail.endpoint}"
    end
  else
    env.response.status_code = 404
    {"error" => "must include <file> or <url> parameter"}.to_json
  end
end
