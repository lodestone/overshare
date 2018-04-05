require "yaml"
require "remarkdown"
require "file_utils"
require "uri"

module Overshare
  class Detail
    property endpoint : String
    getter views : (Int32 | Int64) = 0

    def initialize(@endpoint)
      @detail = RememberDetail.new(@endpoint)
    end

    def sid
      @detail.sid
    end

    def uri
      @detail.uri
    end

    def endpoint
      @detail.endpoint
    end

    def persist
      @detail.save
      self
    end

    def nuke
      # TODO: Nuke
    end

    def self.make(endpoint : String)
      new(endpoint).persist
    end

    def self.get(sid : String | Nil)
      return NilDetail.new if sid.nil?
      RecallDetail.new(sid)
    end
  end

  class NilDetail
    property endpoint : String | Nil
    property views : Int64 | Nil
    def redirect_to; end
    def render_html; end
    def retrieve; end
  end

  class DetailYaml
    YAML.mapping(
      endpoint: String,
      sid: String,
      views: Int64
    )
  end

  class RememberDetail
    getter sid : String = ShortId.generate_short_id

    def initialize(@endpoint : String)
      @path_dir = "#{base_dir}/#{@sid}/"
      @path_file = "data.yml"
      @path = "#{@path_dir}#{@path_file}"
      @endpoint_final_destination = "#{@path_dir}#{File.basename(@endpoint)}"
      ensure_path
      uri = URI.parse(@endpoint)
      if uri.scheme == nil || uri.scheme == "file"
        raise "File not found" if !File.exists?(@endpoint)
        FileUtils.cp @endpoint, @endpoint_final_destination
        @endpoint = File.basename(@endpoint)
      end
      @detail = YAML.build do |yaml|
        yaml.mapping do
          yaml.scalar "endpoint"
          yaml.scalar @endpoint
          yaml.scalar "sid"
          yaml.scalar @sid
          yaml.scalar "views"
          yaml.scalar 1
        end
      end
    end

    def render_html
      return Remarkdown.to_html File.read(endpoint_path) if endpoint_path =~ /\.md$/
      return `asciidoctor -s -o - #{endpoint_path}` if endpoint_path =~ /\.adoc$/
    end

    def uri
      "#{Settings["public_host"]}/#{Overshare::Settings["symbol"]}#{sid}"
    end

    def base_dir
      Overshare::Settings["details_dir"]
    end

    def ensure_path
      FileUtils.mkdir_p(@path_dir) unless Dir.exists?(@path_dir)
    end

    def save
      File.open(@path, "w+"){|file| file << @detail }
      self
    end
  end

  class RecallDetail
    getter endpoint : String
    getter sid : String
    getter views : (Int32 | Int64) = 1

    def initialize(@sid : String)
      raise "Access data file ***REJECTED***" if @sid =~ /data\.yml/
      @path = "#{base_dir}/#{@sid}/data.yml"

      # Are we asking for a directory or an exact file?
      if File.exists?("#{base_dir}/#{@sid}") && !File.directory?("#{base_dir}/#{@sid}")
        name =  "#{base_dir}/#{File.dirname(@sid)}/data.yml"
        @sid = File.dirname(@sid)
        @detail = DetailYaml.from_yaml(File.open(name))
        @endpoint = @detail.endpoint
        @detail.views = @detail.views + 1
        @views = @detail.views
        save_detail
      else
        raise "Detail #{@sid} not found at #{@path}" unless File.exists?(@path)
        @detail = DetailYaml.from_yaml(File.open(@path))
        @endpoint = @detail.endpoint
        @detail.views = @detail.views + 1
        @views = @detail.views
        save_detail
      end
    end

    def retrieve
      if File.exists?(endpoint_path)
        File.open(endpoint_path)
      else
        @endpoint
      end
    end

    def render_html
      return Remarkdown.to_html File.read(endpoint_path) if endpoint_path =~ /\.md$/
      return `asciidoctor -s -o - #{endpoint_path}` if endpoint_path =~ /\.adoc$/
    end

    def redirect_to
      return endpoint if url?
      return "/#{Overshare::Settings["symbol"]}/#{@sid}/#{@endpoint}" if file?
    end

    def base_dir
      Overshare::Settings["details_dir"]
    end

    def url?
      !File.exists? endpoint_path
    end

    def file?
      File.exists? endpoint_path
    end

    def endpoint_path
      "#{base_dir}/#{@detail.sid}/#{@endpoint}"
    end

    def uri
      "#{Settings["public_host"]}/#{Settings["symbol"]}#{sid}"
    end

    def data_path
      "#{base_dir}/#{@sid}/data.yml"
    end

    def save_detail
      File.open(data_path, "w+"){|file| file << YAML.dump(@detail) }
    end
  end

  class ShortId
    def self.generate_short_id
      rand(36**7).to_s(36).rjust(6,'x')
    end
  end
end
