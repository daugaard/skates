require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ipvision-skates"
    gem.summary = %Q{Skates is a framework to create EventMachine based XMPP External Components in Ruby. IPVision fork.}
    gem.email = "sbd@ipvision.dk"
    gem.homepage = "http://github.com/daugaard/skates"
    gem.authors = ["julien Genestoux", "Søren Blond Daugaard"]

    gem.add_dependency('eventmachine', ">= 0.12.10")
    gem.add_dependency('log4r')
    gem.add_dependency('nokogiri', ">= 1.4.1")
    gem.add_dependency('superfeedr-sax-machine', ">= 0.0.23")
    gem.add_dependency('templater')
    gem.requirements = ["eventmachine", "yaml", "fileutils", "log4r", "nokogiri", "superfeedr-sax-machine", "templater", "optparse", "digest/sha1", "base64", "resolv", "utf8cleaner"]
    gem.executables = "skates"
    gem.files = [ "bin/skates", 
                  "lib/skates.rb", 
                  "lib/skates/ext/array.rb", 
                  "lib/skates/base/controller.rb", 
                  "lib/skates/base/view.rb", 
                  "lib/skates/base/stanza.rb", 
                  "lib/skates/client_connection.rb", 
                  "lib/skates/component_connection.rb", 
                  "lib/skates/router/dsl.rb", 
                  "lib/skates/router.rb", 
                  "lib/skates/runner.rb", 
                  "lib/skates/generator.rb", 
                  "lib/skates/xmpp_connection.rb", 
                  "lib/skates/xmpp_parser.rb", 
                  "LICENSE", 
                  "Rakefile", 
                  "README.rdoc", 
                  "templates/skates/app/controllers/controller.rb", 
                  "templates/skates/app/views/view.rb", 
                  "templates/skates/app/stanzas/stanza.rb", 
                  "templates/skates/config/boot.rb", 
                  "templates/skates/config/config.yaml", 
                  "templates/skates/config/dependencies.rb", 
                  "templates/skates/config/routes.rb", 
                  "templates/skates/script/component",
                  "templates/skates/log/test.log",
                  "templates/skates/log/development.log",
                  "templates/skates/log/production.log",
                  "templates/skates/tmp/pids/README"
                  ]
    gem.rubyforge_project = 'skates'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem jeweler"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'Skates : a framework to create EventMachine based XMPP External Components in Ruby.'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << '--line-numbers'
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

begin
  require 'spec/rake/spectask'
  desc "Run all Spec"
  Spec::Rake::SpecTask.new('spec') do |spec|
    spec.spec_files = FileList['spec/**/*.rb']
    spec.verbose = true
    spec.warning = false
    spec.rcov = true
  end
rescue LoadError
  task :spec do
    abort "Rspec is not available. In order to run rspec, you must: sudo gem install rspec"
  end
end

begin
  require 'spec/rake/verify_rcov'

  RCov::VerifyTask.new(:verify_rcov => 'spec') do |t|
    t.threshold = 100.0
    t.index_html = 'coverage/index.html'
  end
rescue LoadError
  task :spec do
    abort "Rcov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

# These are Rubyforge tasks
begin
  require 'rake/contrib/sshpublisher'
  namespace :rubyforge do

    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

    namespace :release do
      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
            File.read(File.expand_path('~/.rubyforge/user-config.yml'))
        )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/gforge-projects/skates"
        local_dir = 'rdoc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
end


task :install => :build

task :default => :test
