require "./spec_helper"
require "spec-kemal"

describe Overshare do
  it "redirects the root path to the proper location" do
    Kemal.run do
      get "/"
      response.status_code.should eq 302
      response.headers["Location"].should eq Overshare::Settings["root_to"].as_s
    end
  end

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

  it "returns the requested file, unmodified when parsing is not needed" do
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

  it "returns the requested file, unmodified when parsing is not needed" do
    setup_details
    Kemal.run do
      get "/-/nodata/i-have-no-data-file.html"
      response.body.should eq "<html>\n<h1>No data.yml</h1>\n</html>\n"
    end
  end

  it "sets the proper mime type for jpeg files" do
    setup_details
    Kemal.run do
      get "/-nodata/image.jpg"
      response.headers["Content-Type"].should eq("image/jpeg")
    end
  end

  it "sets the proper mime type for html files" do
    setup_details
    Kemal.run do
      get "/-nodata/i-have-no-data-file.html"
      response.headers["Content-Type"].should eq("text/html")
    end
  end

  it "sets the proper mime type for raw markdown files" do
    setup_details
    Kemal.run do
      get "/-xyz987/blog.md"
      response.headers["Content-Type"].should eq("text/x-markdown")
    end
  end

  it "sets the proper mime type for rendered markdown files" do
    setup_details
    Kemal.run do
      get "/-xyz987"
      response.headers["Content-Type"].should eq("text/html")
    end
  end
end
