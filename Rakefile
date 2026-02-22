require 'rake/testtask'
require_relative 'test/test_helper'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
end

task default: :test
