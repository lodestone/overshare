require "spec"
require "../src/overshare"

def setup_details
  FileUtils.cp_r "spec/fixtures/nested", "spec/details/nested" unless Dir.exists?("spec/details/nested")
  FileUtils.cp_r "spec/fixtures/xyz987", "spec/details/xyz987" unless Dir.exists?("spec/details/xyz987")
end
