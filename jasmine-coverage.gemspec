lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH << lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'jasmine/coverage'

Gem::Specification.new do |s|
  s.name = 'jasmine-coverage'
  s.version = Jasmine::Coverage::VERSION
  s.authors = ['Harry Lascelles']
  s.email = ['harry@harrylascelles.com']
  s.homepage = 'https://github.com/firstbanco/jasmine-coverage'
  s.summary = 'A blend of JS unit testing and coverage'
  s.license = 'MIT'

  s.files = Dir["{lib}/**/*"] + ["README.md", 'Rakefile']
  s.require_paths = ['lib']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'jasmine-headless-webkit-firstbanco', '0.9.0.rc.3'
  s.add_dependency 'coffee-script-source'
  s.add_dependency 'headless'
end
