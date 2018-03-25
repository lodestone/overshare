ENV["ENV"] = "test"

require "./spec_helper"
include Oversharing

def setup_details
  FileUtils.cp_r "spec/fixtures/nested", "spec/details/nested" unless Dir.exists?("spec/details/nested")
  FileUtils.cp_r "spec/fixtures/xyz987", "spec/details/xyz987" unless Dir.exists?("spec/details/xyz987")
end

def url
  "https://spacerobots.net"
end

def remove_details
  `rm -rf spec/details/*`
end

describe Oversharing::Detail do
  it "is generally okay" do
    Detail.new("spec/fixtures/fu.pdf").should_not be(nil)
  end

  describe "#new" do
    it "handles file:// uris" do
      detail = Detail.new("spec/fixtures/usagi.jpg")
      detail.persist
      Detail.get(detail.sid).endpoint.should eq("usagi.jpg")
    end

    it "handles http:// uris" do
      detail = Detail.new(url)
      detail.persist
      Detail.get(detail.sid).endpoint.should eq(url)
    end

    it "has a shortened id" do
      detail = Detail.new(url)
      detail.sid.should match(/^[A-z0-9]{6,6}$/)
    end
  end

  describe "#persist" do
    it "saves the file in the details folder" do
      detail = Detail.new("spec/fixtures/usagi.jpg")
      detail.persist
      File.exists?("spec/details/#{detail.sid}/data.yml").should be_true
      File.exists?("spec/details/#{detail.sid}/usagi.jpg").should be_true
    end
  end

  # describe "#nuke" do
  #   pending "removes the detail" do
  #   end
  # end

  describe "#make" do
    it "makes (new and persist) a Detail" do
      detail = Detail.make(url)
      Detail.get(detail.sid).endpoint.should eq(url)
    end
  end

  describe "#get" do
    it "handles nested folders" do
      setup_details
      detail = Detail.get("nested/twice")
      detail.endpoint.should eq("nested-twice.md")
      remove_details
    end

    it "handles regular files (markdown)" do
      setup_details
      detail = Detail.get("xyz987")
      detail.endpoint.should eq("blog.md")
      remove_details
    end

    it "tracks the access count" do
      setup_details
      detail = Detail.get("xyz987")
      detail.views.should eq(2)
      remove_details
    end

    it "returns the file endpoint" do
      setup_details
      detail = Detail.get("xyz987")
      detail.retrieve.should be_a(File)
      remove_details
    end

    it "returns the url endpoint" do
      detail = Detail.get(Detail.make(url).sid)
      detail.retrieve.should eq(url)
    end
  end

  # Rendering
  # it "renders markdown" do
  # end

  # it "renders asciidoc" do
  # end

  # Caching
  # it "caches markdown until source changes" do
  # end

  # Ephemerality
  # it "expires after X period of time" do
  # end

  # Cleanup and Teardown
  # TODO: Fix this!
  Spec.after_each do
    puts "This isn't running"
    remove_details
  end
end
