require "rubygems"
require "bundler"
require "bundler/cli"

puts "Using gemfile at #{$gem_file_location}"

Bundler::CLI.new.invoke :install, [], :gemfile => $gem_file_location , :path => "target/bundled-gems", :quiet => true