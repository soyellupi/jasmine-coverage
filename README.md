## Jasmine Coverage

A transcendent blend of useful JS unit testing and colourful coverage graphs.

This gem allows [Jasmine Headless Webkit](http://johnbintz.github.com/jasmine-headless-webkit/)
to be run against a Rails application's Javascript tests, and then produces a coverage report, optionally
failing it if it falls below a configurable level.

Coverage is provided by the [jscoverage](http://siliconforks.com/jscoverage/manual.html) project.

## Installation

First, ensure you have a binary of [jscoverage](http://siliconforks.com/jscoverage/manual.html)
available on your path. The installation steps are on the webpage.

Then, add the following in your Gemfile. Note, there were a raft of small issues with older versions
of [Jasmine Headless Webkit](http://johnbintz.github.com/jasmine-headless-webkit/), so for the moment you must use
the master branch of that project.

    gem 'jasmine-coverage'
    gem 'jasmine-headless-webkit', :git => 'git://github.com/johnbintz/jasmine-headless-webkit.git'

Finally, add this to your Rakefile

    require 'jasmine/coverage'

## Usage

To use jasmine-coverage, run the rake task.

    bundle exec rake jasmine:coverage

## Output

You will see the tests execute, then a large blob of text, and finally a summary of the test coverage results.
An HTML file will also be saved that lets you view the results graphically, but only if served up from a server,
not local disk. This is because the jscoverage generated report page needs to make a request for a local json
file, and browsers won't allow a local file to read another local file off disk.

To reiterate: if you try to open the report file locally, you will see NETWORK_ERR: XMLHttpRequest Exception,
as the browser may not access the json file locally. However if your build server allows you to browse project build
artefacts, you can view the visual report as the json is served from there too.

Files generated will be

    target/jscoverage/jscoverage.html  -  The visual report shell
    target/jscoverage/jscoverage.json  -  The report data
    target/jscoverage/jscoverage-test-rig.html  -  The actual page that the tests executed in

## Configuration

You can set a failure level percentage.

    bundle exec rake jasmine:coverage JASMINE_COVERAGE_MINIMUM=75

In addition, as jasmine-coverage has to create a single folder environment for the Javascript sandbox to function correctly, it has to copy
files into the _target/jscoverage/test-rig_ folder. By default, this is then cleaned up for you if the tests pass. If you'd like to see what files
it generates regardless, you can specify that in an environment variable.

    bundle exec rake jasmine:coverage JASMINE_COVERAGE_KEEP_TEST_RIG=true

You can also specify if you want missing coverage warnings

    bundle exec rake jasmine:coverage JASMINE_COVERAGE_WARNINGS=true

## How it works

First Sprockets is interrogated to get a list of JS files concerned. This way, the right JS files
are required *in the same order that your app uses them*. JSCoverage then runs over them, and outputs the
instrumented files in the target folder. Next, Jasmine Headless Webkit runs as normal, but a couple of monkey
patches intercept the locations of the javascript files it expects to find, rerouting them to the instrumented versions.

The data we get from the coverage can only "leave" the JS sandbox one way: via the console. This is why you see such
a large block of Base64 encoded rubbish flying past as the build progresses. The console data is captured by Jasmine
Coverage, which decodes it and builds the results HTML page, and gives a short summary in the console.

You're done.

## Mac Support

The tool uses the headless gem, which needs to create an X virtual frame buffer. Linux machines should work out the box, 
but since Mac uses Quartz, you may get 

    Xvfb not found on your system
    
To solve that just install XQuartz and add /usr/X11/bin to your PATH (thanks @shell).
