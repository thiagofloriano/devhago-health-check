require 'rake/testtask'
require 'bundler/gem_tasks'

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = false
end

# Default task
task default: :test

# Custom task to run specific test file
# Usage: rake test:file TEST=test/models/health_check_snapshot_test.rb
namespace :test do
  task :file do
    test_file = ENV['TEST']
    if test_file
      ruby "-Ilib:test #{test_file}"
    else
      puts "Usage: rake test:file TEST=test/path/to/test.rb"
    end
  end
end

desc 'Run tests with verbose output'
task :test_verbose do
  ENV['VERBOSE'] = 'true'
  Rake::Task['test'].invoke
end

desc 'Show test statistics'
task :test_stats do
  total_tests = 0
  total_assertions = 0
  
  Dir.glob('test/**/*_test.rb').each do |file|
    content = File.read(file)
    tests = content.scan(/^\s*it ['"]/).length
    assertions = content.scan(/assert_/).length
    
    total_tests += tests
    total_assertions += assertions
    
    puts "#{file}: #{tests} tests, ~#{assertions} assertions"
  end
  
  puts "\nTotal: #{total_tests} tests, ~#{total_assertions} assertions"
end
