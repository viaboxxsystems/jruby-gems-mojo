require "spec_helper"

describe "gemcutter's dependency API" do
  let(:source_uri) { "http://localgemserver.test" }

  it "should use the API" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle :install, :artifice => "endpoint"
    out.should include("Fetching gem metadata from #{source_uri}")
    should_be_installed "rack 1.0.0"
  end

  it "should URI encode gem names" do
    gemfile <<-G
      source "#{source_uri}"
      gem " sinatra"
    G

    bundle :install, :artifice => "endpoint"
    out.should include("Could not find gem ' sinatra")
  end

  it "should handle nested dependencies" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rails"
    G

    bundle :install, :artifice => "endpoint"
    out.should include("Fetching gem metadata from #{source_uri}/...")
    should_be_installed(
      "rails 2.3.2",
      "actionpack 2.3.2",
      "activerecord 2.3.2",
      "actionmailer 2.3.2",
      "activeresource 2.3.2",
      "activesupport 2.3.2")
  end

  it "should handle multiple gem dependencies on the same gem" do
    gemfile <<-G
      source "#{source_uri}"
      gem "net-sftp"
    G

    bundle :install, :artifice => "endpoint"
    should_be_installed "net-sftp 1.1.1"
  end

  it "should use the endpoint when using --deployment" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G
    bundle :install, :artifice => "endpoint"

    bundle "install --deployment", :artifice => "endpoint"
    out.should include("Fetching gem metadata from #{source_uri}")
    should_be_installed "rack 1.0.0"
  end

  it "handles git dependencies that are in rubygems" do
    build_git "foo" do |s|
      s.executables = "foobar"
      s.add_dependency "rails", "2.3.2"
    end

    gemfile <<-G
      source "#{source_uri}"
      git "file:///#{lib_path('foo-1.0')}" do
        gem 'foo'
      end
    G

    bundle :install, :artifice => "endpoint"

    should_be_installed("rails 2.3.2")
  end

  it "handles git dependencies that are in rubygems using --deployment" do
    build_git "foo" do |s|
      s.executables = "foobar"
      s.add_dependency "rails", "2.3.2"
    end

    gemfile <<-G
      source "#{source_uri}"
      gem 'foo', :git => "file:///#{lib_path('foo-1.0')}"
    G

    bundle :install, :artifice => "endpoint"

    bundle "install --deployment", :artifice => "endpoint"

    should_be_installed("rails 2.3.2")
  end

  it "falls back when the API errors out" do
    simulate_platform mswin

    gemfile <<-G
      source "#{source_uri}"
      gem "rcov"
    G

    bundle :install, :fakeweb => "windows"
    out.should include("\nFetching full source index from #{source_uri}")
    should_be_installed "rcov 1.0.0"
  end

  it "falls back when hitting the Gemcutter Dependency Limit" do
    gemfile <<-G
      source "#{source_uri}"
      gem "activesupport"
      gem "actionpack"
      gem "actionmailer"
      gem "activeresource"
      gem "thin"
      gem "rack"
      gem "rails"
    G
    bundle :install, :artifice => "endpoint_fallback"
    out.should include("\nFetching full source index from #{source_uri}")

    should_be_installed(
      "activesupport 2.3.2",
      "actionpack 2.3.2",
      "actionmailer 2.3.2",
      "activeresource 2.3.2",
      "activesupport 2.3.2",
      "thin 1.0.0",
      "rack 1.0.0",
      "rails 2.3.2")
  end

  it "falls back when Gemcutter API doesn't return proper Marshal format" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle :install, :artifice => "endpoint_marshal_fail"
    out.should include("\nFetching full source index from #{source_uri}")
    should_be_installed "rack 1.0.0"
  end

  it "timeouts when Bundler::Fetcher redirects too much" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle :install, :artifice => "endpoint_redirect"
    out.should match(/Too many redirects/)
  end

  it "should use the modern index when the --full-index" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle "install --full-index", :artifice => "endpoint"
    out.should include("Fetching source index from #{source_uri}")
    should_be_installed "rack 1.0.0"
  end

  it "fetches again when more dependencies are found in subsequent sources" do
    build_repo2 do
      build_gem "back_deps" do |s|
        s.add_dependency "foo"
      end
      FileUtils.rm_rf Dir[gem_repo2("gems/foo-*.gem")]
    end

    gemfile <<-G
      source "#{source_uri}"
      source "#{source_uri}/extra"
      gem "back_deps"
    G

    bundle :install, :artifice => "endpoint_extra"
    should_be_installed "back_deps 1.0"
  end

  it "prints API output properly with back deps" do
    build_repo2 do
      build_gem "back_deps" do |s|
        s.add_dependency "foo"
      end
      FileUtils.rm_rf Dir[gem_repo2("gems/foo-*.gem")]
    end

    gemfile <<-G
      source "#{source_uri}"
      source "#{source_uri}/extra"
      gem "back_deps"
    G

    bundle :install, :artifice => "endpoint_extra"

    output = <<OUTPUT
Fetching gem metadata from http://localgemserver.test/..
Fetching gem metadata from http://localgemserver.test/extra/.
OUTPUT
    out.should include(output)
  end

  it "does not fetch every specs if the index of gems is large when doing back deps" do
    build_repo2 do
      build_gem "back_deps" do |s|
        s.add_dependency "foo"
      end
      build_gem "missing"
      # need to hit the limit
      1.upto(Bundler::Source::Rubygems::FORCE_MODERN_INDEX_LIMIT) do |i|
        build_gem "gem#{i}"
      end

      FileUtils.rm_rf Dir[gem_repo2("gems/foo-*.gem")]
    end

    gemfile <<-G
      source "#{source_uri}"
      source "#{source_uri}/extra"
      gem "back_deps"
    G

    bundle :install, :artifice => "endpoint_extra_missing"
    should_be_installed "back_deps 1.0"
  end

  it "uses the endpoint if all sources support it" do
    gemfile <<-G
      source "#{source_uri}"

      gem 'foo'
    G

    bundle :install, :artifice => "endpoint_api_missing"
    should_be_installed "foo 1.0"
  end

  it "fetches again when more dependencies are found in subsequent sources using --deployment" do
    build_repo2 do
      build_gem "back_deps" do |s|
        s.add_dependency "foo"
      end
      FileUtils.rm_rf Dir[gem_repo2("gems/foo-*.gem")]
    end

    gemfile <<-G
      source "#{source_uri}"
      source "#{source_uri}/extra"
      gem "back_deps"
    G

    bundle :install, :artifice => "endpoint_extra"

    bundle "install --deployment", :artifice => "endpoint_extra"
    should_be_installed "back_deps 1.0"
  end

  it "does not refetch if the only unmet dependency is bundler" do
    gemfile <<-G
      source "#{source_uri}"

      gem "bundler_dep"
    G

    bundle :install, :artifice => "endpoint"
    out.should include("Fetching gem metadata from #{source_uri}")
  end

  it "should install when EndpointSpecification with a bin dir owned by root", :sudo => true do
    sudo "mkdir -p #{system_gem_path("bin")}"
    sudo "chown -R root #{system_gem_path("bin")}"

    gemfile <<-G
      source "#{source_uri}"
      gem "rails"
    G
    bundle :install, :artifice => "endpoint"
    should_be_installed "rails 2.3.2"
  end

  it "installs the binstubs" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle "install --binstubs", :artifice => "endpoint"

    gembin "rackup"
    out.should == "1.0.0"
  end

  it "installs the bins when using --path and uses autoclean" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle "install --path vendor/bundle", :artifice => "endpoint"

    vendored_gems("bin/rackup").should exist
  end

  it "installs the bins when using --path and uses bundle clean" do
    gemfile <<-G
      source "#{source_uri}"
      gem "rack"
    G

    bundle "install --path vendor/bundle --no-clean", :artifice => "endpoint"

    vendored_gems("bin/rackup").should exist
  end

  it "prints post_install_messages" do
    gemfile <<-G
      source "#{source_uri}"
      gem 'rack-obama'
    G

    bundle :install, :artifice => "endpoint"
    out.should include("Post-install message from rack:")
  end

  it "should display the post install message for a dependency" do
    gemfile <<-G
      source "#{source_uri}"
      gem 'rack_middleware'
    G

    bundle :install, :artifice => "endpoint"
    out.should include("Post-install message from rack:")
    out.should include("Rack's post install message")
  end

  context "when using basic authentication" do
    let(:user)     { "user" }
    let(:password) { "pass" }
    let(:basic_auth_source_uri) do
      uri          = URI.parse(source_uri)
      uri.user     = user
      uri.password = password

      uri
    end

    it "passes basic authentication details and strips out creds" do
      gemfile <<-G
        source "#{basic_auth_source_uri}"
        gem "rack"
      G

      bundle :install, :artifice => "endpoint_basic_authentication"
      out.should_not include("#{user}:#{password}")
      should_be_installed "rack 1.0.0"
    end

    it "strips http basic authentication creds for modern index" do
      gemfile <<-G
        source "#{basic_auth_source_uri}"
        gem "rack"
      G

      bundle :install, :artifice => "endopint_marshal_fail_basic_authentication"
      out.should_not include("#{user}:#{password}")
      should_be_installed "rack 1.0.0"
    end

    it "strips http basic auth creds when it can't reach the server" do
      gemfile <<-G
        source "#{basic_auth_source_uri}"
        gem "rack"
      G

      bundle :install, :artifice => "endpoint_500"
      out.should_not include("#{user}:#{password}")
    end
  end
end
