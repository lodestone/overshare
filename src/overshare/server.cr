require "remarkdown"
require "kemal"
require "kemal-session"
require "kemal-basic-auth"
require "mime"
require "./details"
require "./settings"
#
# module Raw
#   macro embed(filename, io)
#     # {{ io.id }} << {{`cat #{filename}`.stringify}}
#     filename
#   end
# end
#
# Kilt.register_engine("", Raw.embed)

before_all do |env|
  env.response.content_type = "application/json"
end

def four_oh_four_message
  %Q[{"message": "Error 404: It's so dark in here"}]
end

def handle_uploaded_tmpfile(point)
  FileUtils.mv point.tmpfile.path, new_point = "/tmp/#{point.filename}"
  new_point
end

def extract_point_from_params(env)
  point = env.params.body["uri"]? || env.params.body["url"]? || env.params.body["endpoint"]? || env.params.files["file"]? || env.params.files["endpoint"]?
  point = handle_uploaded_tmpfile(point) if point.is_a? Kemal::FileUpload
  point
end

def authorized(username, password)
  username_ok = Overshare::Settings["username"] == username
  password_ok = Overshare::Settings["password"] == password
  username_ok && password_ok
end

def check_authorization(env)
  authorization = env.request.headers["Authorization"]?
  username, password = Base64.decode_string(authorization["Basic".size + 1..-1]).split(":") if authorization
  reject_request(env) if !authorized(username, password)
end

def reject_request(env)
  env.response.status_code = 401
  env.response.print "Forbidden"
  env.response.close
end

post "/#{Overshare::Settings["symbol"]}" do |env|
  check_authorization(env)
  if point = extract_point_from_params(env)
    detail = Overshare::Detail.make(point)
    {"message" => "Created", "url" => detail.uri}.to_json
  else
    {"message" => "ERROR: must include <endpoint> parameter"}.to_json
  end
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
  rescue
    halt env, status_code: 404, response: four_oh_four_message
  end
end

def go_detail(env)
  sid = env.params.url["sid"]?
  if /.*data\.yml$/ =~ sid
    raise "REJECTED"
  end
  if File.exists?("#{Overshare::Settings["details_dir"]}/#{sid}") && !File.directory?("#{Overshare::Settings["details_dir"]}/#{sid}")
    ext = File.extname("#{sid}")
    mime_type = Mime.from_ext(ext)
    send_file env, "#{Overshare::Settings["details_dir"]}/#{sid}", mime_type
  else
    if detail = Overshare::Detail.get(sid)
      env.response.content_type = "text/html"
      if html = detail.render_html
        layout = File.read("content/templates/layout.html")
        string = layout.gsub("{{ CONTENT }}", html)
        string
      else
        env.redirect detail.redirect_to || "/"
      end
    else
      raise "HELL"
    end
  end
end

# get "/=*sid" do |env|
#   begin
#     if sid = env.params.url["sid"]?
#       send_file env, "details/#{sid}"
#     else
#       halt env, status_code: 404, response: four_oh_four_message
#     end
#   rescue error
#     log "ERROR: #{error}"
#     halt env, status_code: 404, response: four_oh_four_message
#   end
# end

# get "/~*sid" do |env|
#   if detail = Overshare::Detail.get(env.params.url["sid"]?)
#     if html = detail.render_html
#       layout = File.read("content/templates/layout.html")
#       layout.gsub("{{ CONTENT }}", html)
#     else
#       env.redirect detail.redirect_to || "/"
#     end
#   else
#     halt env, status_code: 404, response: four_oh_four_message
#   end
# end
