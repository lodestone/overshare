require "./spec_helper"
require "spec-kemal"

describe Overshare do
  # You can use get,post,put,patch,delete to call the corresponding route.
  it "is basically okay" do
    setup_details
    Kemal.run do
      get "/-/nested/twice/nested-twice.md"
      response.body.should eq "# I am Nested Twice\n"
    end
  end
end
