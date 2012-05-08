require "rubygems"
require "faker"
require "prawn"

100.times do
  puts "Hello #{Faker::Name.name}"
end

Prawn::Document.generate("hello.pdf") do
  text "Hello World!"
end
