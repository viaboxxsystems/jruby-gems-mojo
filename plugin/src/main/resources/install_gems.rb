require "rubygems"
require "bundler"
require "bundler/cli"
bundled_gems_path = "#{$base_dir}/bundled-gems"

puts "Using gemfile at #{$gem_file_location}"
puts "Bundled gems are loaded from #{bundled_gems_path}"

Bundler::CLI.new.invoke :install, [], :gemfile => $gem_file_location , :path => bundled_gems_path, :quiet => true