require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--color"
  t.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec