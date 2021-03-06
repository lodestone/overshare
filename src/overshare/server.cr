require "remarkdown"
require "kemal"
require "kemal-session"
require "kemal-basic-auth"
require "mime"
require "./details"
require "./settings"

module ETagGuardian
  def etag_guard(context : HTTP::Server::Context, file_path : String)
    etag = %{W/"#{File.info(file_path).modification_time.to_unix.to_s}"}
    context.response.headers["ETag"] = etag
    etag_match = context.request.headers["If-None-Match"]? && context.request.headers["If-None-Match"] == etag
    if etag_match
      context.response.headers.delete "Content-Type"
      context.response.content_length = 0
      context.response.status_code = 304 # not modified
      context.response.close
    end
    etag_match
  end
end
include ETagGuardian

class CacheControlHandler < Kemal::Handler
  def call(context)
    context.response.headers["Cache-Control"] = "public, max-age=60480"
    call_next context
  end
end
add_handler CacheControlHandler.new

class IndexHandler < Kemal::Handler
  include ETagGuardian

  def call(context)
    if context.request.path.includes? '\0'
      context.response.status_code = 400
      return
    end

    public_dir = Overshare::Settings["static_dir"].as_s
    path = File.join(public_dir, context.request.path)

    p path
    # No file match under the public directory, carry on...
    return call_next(context) if !File.exists?(path)

    # Check our etag, return if match is found
    return if etag_guard(context, path)

    # Now we know the public (not a directory) file exists, conditionally send file to client...
    return send_file(context, path) if !File.directory?(path)

    # Now we know a public directory exists, send the index.html if available...
    return send_file(context, File.join(path, "index.html")) if File.exists?(File.join(path, "index.html"))

    # Otherwise, carry on...
    call_next context
  end
end
add_handler IndexHandler.new

error 404 do
  "TODO: Make a 404 page."
end

error 500 do
  "TODO: Make a 500 page"
end

serve_static false

Kemal.config.host_binding = Overshare::Settings["host"].as_s
Kemal.config.port = Overshare::Settings["port"].as_i

before_all do |env|
  env.response.content_type = "application/json"
end

def four_oh_four_message
  %Q[{"message": "Error 404: It's so dark in here"}]
end

def handle_uploaded_tmpfile(point)
  FileUtils.mv point.tempfile.path, new_point = "/tmp/#{point.filename}"
  new_point
end

def extract_point_from_params(env)
  if env.params.query
    point = env.params.query["uri"]? || env.params.query["url"]? || env.params.query["endpoint"]?
  end

  if !point && env.params.body
    point = env.params.body["uri"]? || env.params.body["url"]? || env.params.body["endpoint"]?
  end

  point = handle_uploaded_tmpfile(point) if point.is_a? Kemal::FileUpload
  point
end

def authorized(username, password)
  username_ok = Overshare::Settings["username"] == username
  password_ok = Overshare::Settings["password"] == password
  username_ok && password_ok
end

def check_auth(env)
  authorization = env.request.headers["Authorization"]?
  username, password = Base64.decode_string(authorization["Basic".size + 1..-1]).split(":") if authorization
  authorized(username, password)
end

def check_key(env)
  env.params.query["key"]? == Overshare::Settings["api_key"]
end

def access_granted?(env)
  access_okay = check_key(env) || check_auth(env)
  env.response.respond_with_error "Forbidden", 401 unless access_okay
  access_okay
end

post "/#{Overshare::Settings["symbol"]}" do |env|
  next unless access_granted?(env)
  if point = extract_point_from_params(env)
    detail = Overshare::Detail.make(point)
    url = detail.uri
    {"message" => "Created", "url" => url, Overshare::Settings["url_key"] => url}.to_json
  else
    {"message" => "ERROR: must include <endpoint> parameter"}.to_json
  end
end

get "/" do |env|
  env.redirect Overshare::Settings["root_to"].as_s
end

get "/#{Overshare::Settings["symbol"]}/*sid" do |env|
  begin
    go_detail(env)
  rescue
    halt env, status_code: 404, response: four_oh_four_message
  end
end

get "/#{Overshare::Settings["symbol"]}*sid" do |env|
  begin
    go_detail(env)
  rescue ex
    log ex.to_s
    halt env, status_code: 404, response: four_oh_four_message
  end
end

def go_detail(env)
  sid = env.params.url["sid"]?
  if /.*data\.yml$/ =~ sid
    raise "Auth Failed"
  end
  # Requesting a literal file
  if File.exists?("#{Overshare::Settings["details_dir"]}/#{sid}") && !File.directory?("#{Overshare::Settings["details_dir"]}/#{sid}")
    log "#{Time.now} Serving:::: #{Overshare::Settings["details_dir"]}/#{sid} FROM //#{env.request.host_with_port}#{env.request.path}"
    ext = File.extname("#{sid}").gsub(".", "")
    path = "#{Overshare::Settings["details_dir"]}/#{sid}"
    mime_type = MIME.from_extension(ext)
    env.response.content_type = mime_type.to_s
    return if etag_guard(env, path)
    return send_file env, path, mime_type
  else # Requesting a url or something we need to parse
    if detail = Overshare::Detail.get(sid)
      log "#{Time.now} Rendering:::: #{Overshare::Settings["details_dir"]}/#{sid} FROM //#{env.request.host_with_port}#{env.request.path}"
      env.response.content_type = "text/html"
      if html = detail.render_html
        layout = File.read("content/templates/layout.html")
        string = layout.gsub("{{ CONTENT }}", html)
        return string
      else
        env.redirect detail.redirect_to || "/"
      end
    else
      raise "Not Found"
    end
  end
end
