require "yaml"
require "file_utils"
require "uri"

module Oversharing
  class Detail
    property endpoint : String
    getter views : (Int32 | Int64) = 0

    def initialize(@endpoint : String)
      @detail = RememberDetail.new(@endpoint)
    end

    def sid
      @detail.sid
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

    def self.get(sid)
      RecallDetail.new(sid)
    end
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

    def base_dir
      Oversharing::Settings["details_dir"]
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
      @path = "#{base_dir}/#{@sid}/data.yml"
      raise "Detail #{@sid} not found at #{@path}" unless File.exists?(@path)
      @detail = DetailYaml.from_yaml(File.open(@path))
      @endpoint = @detail.endpoint
      @detail.views = @detail.views + 1
      @views = @detail.views
      save_detail
    end

    def retrieve
      if File.exists?(endpoint_path)
        File.open(endpoint_path)
      else
        @endpoint
      end
    end

    def base_dir
      Oversharing::Settings["details_dir"]
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

    def save_detail
      File.open(@path, "w+"){|file| file << YAML.dump(@detail) }
    end
  end

  class ShortId
    def self.generate_short_id
      rand(36**7).to_s(36).rjust(6,'x')
    end
  end
end
