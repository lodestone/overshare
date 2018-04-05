require "spec"
require "../src/overshare"

def setup_details
  FileUtils.cp_r "spec/fixtures/nested", "spec/details/nested" unless Dir.exists?("spec/details/nested")
  FileUtils.cp_r "spec/fixtures/xyz987", "spec/details/xyz987" unless Dir.exists?("spec/details/xyz987")
  FileUtils.cp_r "spec/fixtures/abc123", "spec/details/abc123" unless Dir.exists?("spec/details/abc123")
  FileUtils.cp_r "spec/fixtures/nodata", "spec/details/nodata" unless Dir.exists?("spec/details/nodata")
end
