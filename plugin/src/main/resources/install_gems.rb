require "rubygems"
require "bundler"
require "bundler/cli"
Bundler::CLI.new.invoke :install, [], :path => "target/bundled-gems", :quiet => true