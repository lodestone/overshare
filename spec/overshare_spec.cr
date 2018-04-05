require "./spec_helper"
require "spec-kemal"

describe Overshare do
  # You can use get,post,put,patch,delete to call the corresponding route.
  it "returns the requested file, unmodified" do
    setup_details
    Kemal.run do
      get "/-/nested/twice/nested-twice.md"
      response.body.should eq "# I am Nested Twice\n"
    end
  end

  it "parses the file if needed" do
    setup_details
    Kemal.run do
      get "/-/nested/twice"
      response.body.should match /.*\<h1.*\>I am Nested Twice\<\/h1\>.*/
    end
  end

  it "returns the requested fil, unmodified when parsing is not needed" do
    setup_details
    Kemal.run do
      get "/-/abc123"
      response.status_code.should eq 302
      response.headers["Location"].should eq "/-/abc123/fu.pdf"
    end
  end

  it "redirects when appropriate" do
    url = "http://nx.is"
    detail = Detail.make(url)
    get "/-/#{detail.sid}"
    response.status_code.should eq 302
    response.headers["Location"].should eq url
  end

  it "returns the requested fil, unmodified when parsing is not needed" do
    Kemal.run do
      get "/-/nodata/i-have-no-data-file.html"
      response.body.should match /.*\<h1.*\>I am Nested Twice\<\/h1\>.*/
    end
  end
end
