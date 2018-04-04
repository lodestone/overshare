require "remarkdown"
require "kemal"
require "kemal-session"
require "kemal-basic-auth"
require "./details"
require "./settings"

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
  username == "auth" && password == "password86"
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

post "/+" do |env|
  check_authorization(env)
  if point = extract_point_from_params(env)
    detail = Overshare::Detail.make(point)
    {"message" => "Created", "url" => detail.uri}.to_json
  else
    {"message" => "ERROR: must include <endpoint> parameter"}.to_json
  end
end

get "/+*sid" do |env|
  begin
    detail = Overshare::Detail.get(env.params.url["sid"]?)
    env.redirect detail.redirect_to || "/" if detail
  rescue error
    log "ERROR: #{error}"
    halt env, status_code: 404, response: four_oh_four_message
  end
end

get "/-/*sid" do |env|
  begin
    sid = env.params.url["sid"]?
    if /.*data\.yml$/ =~ sid
      halt env, status_code: 404, response: four_oh_four_message
    end
    if File.exists?("details/#{sid}") && !File.directory?("details/#{sid}")
      send_file env, "details/#{sid}"
    else
      if detail = Overshare::Detail.get(sid)
        if html = detail.render_html
          layout = File.read("content/templates/layout.html")
          layout.gsub("{{ CONTENT }}", html)
        else
          env.redirect detail.redirect_to || "/"
        end
      else
        halt env, status_code: 404, response: four_oh_four_message
      end
    end
  rescue
    halt env, status_code: 404, response: four_oh_four_message
  end
end

get "/=*sid" do |env|
  begin
    if sid = env.params.url["sid"]?
      send_file env, "details/#{sid}"
    else
      halt env, status_code: 404, response: four_oh_four_message
    end
  rescue error
    log "ERROR: #{error}"
    halt env, status_code: 404, response: four_oh_four_message
  end
end

get "/~*sid" do |env|
  if detail = Overshare::Detail.get(env.params.url["sid"]?)
    if html = detail.render_html
      layout = File.read("content/templates/layout.html")
      layout.gsub("{{ CONTENT }}", html)
    else
      env.redirect detail.redirect_to || "/"
    end
  else
    halt env, status_code: 404, response: four_oh_four_message
  end
end
