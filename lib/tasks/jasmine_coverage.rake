env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
if env =~ /^(development|test)$/
  require 'rake'
  require 'base64'

  namespace :jasmine do
    desc 'Runs jasmine with a coverage report'
    task :coverage do

      require 'jasmine-headless-webkit'
      # Instill our patches for jasmine-headless to work
      require_relative 'jasmine_headless_coverage_patches'

      # We use jasmine-headless-webkit, since it has excellent programmatic integration with Jasmine
      # But... the 'headless' part of it doesn't work on TeamCity, so we use the headless gem
      require 'headless'

      headless = Headless.new
      headless.start

      # Preprocess the JS files to add instrumentation
      output_dir = File.expand_path('target/jscoverage/')
      instrumented_dir = output_dir+'/instrumented/'
      FileUtils.rm_rf output_dir
      FileUtils.mkdir_p instrumented_dir

      # The reprocessing folder map. Use an environment variable if available.
      files_map = ENV['JS_SRC_PATH'] ? {ENV['JS_SRC_PATH'] => instrumented_dir+'public'} : {
        File.expand_path('app/assets/javascripts') => instrumented_dir+'app',
        File.expand_path('lib/assets/javascripts') => instrumented_dir+'lib',
        File.expand_path('public/javascripts') => instrumented_dir+'public',
      }

      # Instrument the source files into the instrumented folders
      files_map.keys.each do |folder|
        instrument(folder, files_map[folder])
        # Also hoist up the eventual viewing files
        FileUtils.mv(Dir.glob(files_map[folder]+'/jscoverage*'), output_dir)
      end

      Jasmine::Coverage.warnings = ENV['JASMINE_COVERAGE_WARNINGS'] || 'false'
      Jasmine::Coverage.resources = files_map
      Jasmine::Coverage.output_dir = output_dir
      test_rig_folder = "#{Jasmine::Coverage.output_dir}/test-rig"

      rr_file = "#{output_dir}/rawreport.txt"
      puts "\nCoverage will now be run. Expect a large block of compiled coverage data. This will be processed for you into target/jscoverage (#{rr_file}).\n\n"

      # Check we can write to the output file
      begin
        File.open(rr_file, 'w') { |f| f.write('test-write') }
        File.delete(rr_file)
      rescue
        raise "There was an error writing to the report file #{rr_file}.\nDo you have permissions to do so?"
      end

      # Run Jasmine using the original config.
      status_code = Jasmine::Headless::Runner.run(
        # Any options from the options.rb file in jasmine-headless-webkit can be used here.

        :reporters => [['Console'], ['File', rr_file]]
      )
      errStr = <<-EOS
**********************************************************************************************

JSCoverage exited with error code: #{status_code}

This implies one of six things:
0) Your JS files had exactly zero instructions. Are they all blank or just comments?
1) The Jasmine Headless gem failed. Run bundle exec rake jasmine:headless to see what it might be.
2) A test failed - you should be able to see the errors just above this text block (or run bundle exec rake jasmine:headless to see a simple error without coverage).
3) The sourcecode has a syntax error (which JSLint should find)
4) An error occurred in a deferred block, e.g. a setTimeout or underscore _.defer. This caused a window error which Jasmine will never see.
5) The source files are being loaded out of sequence (so global variables are not being declared in order)
   To check this, run bundle exec jasmine-headless-webkit -l to see the ordering

In any case, try running the standard jasmine command to get better errors:

bundle exec rake jasmine:headless

Finally, try opening the test-rig in firefox to see the tests run in a browser and get a stacktrace. Chrome has strict security settings
that make this difficult since it accesses the local filesystem from Javascript (but you can switch the settings off at the command line).
The test rig file needs to load JS directly off disk, which Chrome prevents by default. Your best bet is to open the rig in Firefox.

The file can be found here: #{test_rig_folder}/jscoverage-test-rig.html

**********************************************************************************************

      EOS

      fail errStr if status_code == 1
      # Delete the test_rig folder if not required
      if ENV['JASMINE_COVERAGE_KEEP_TEST_RIG'] == 'false'
        FileUtils.rm_rf test_rig_folder
      else
        p "A copy of the page and files that were used as the jasmine test environment can be found here: #{test_rig_folder}"
      end

      # Obtain the console log, which includes the coverage report encoded within it
      contents = File.open(rr_file) { |f| f.read }
      # Get our Base64.
      json_report_enc = contents.split(/ENCODED-COVERAGE-EXPORT-STARTS:/m)[1]
      # Provide warnings to use
      warning_regex = /^CONSOLE\|\|.{1,6}WARNING.{4}(.*).{5}$/
      warnings = contents.scan warning_regex
      if (warnings.length != 0)
        puts "Detected #{warnings.length} warnings:"
        puts warnings
        fail "Aborting. All lines must be covered by a test." if ENV['MUST_COVER_ALL']
      else
        puts "No warnings detected."
      end if
        # Remove the junk at the end
        json_report_enc_stripped = json_report_enc[0, json_report_enc.index("\"")] rescue json_report_enc_stripped

      # Unpack it from Base64
      json_report = Base64.decode64(json_report_enc_stripped)

      # Save the coverage report where the GUI html expects it to be
      File.open("#{output_dir}/jscoverage.json", 'w') { |f| f.write(json_report) }

      # Modify the jscoverage.html so it knows it is showing a report, not running a test
      File.open("#{output_dir}/jscoverage.js", 'a') { |f| f.write("\njscoverage_isReport = true;") }

      if json_report_enc.index("No Javascript was found to test coverage for").nil?
        # Check for coverage failure
        total_location = json_report_enc.index("% Total")
        coverage_pc = json_report_enc[total_location-3, 3].to_i

        conf = (ENV['JSCOVERAGE_MINIMUM'] || ENV['JASMINE_COVERAGE_MINIMUM'])
        fail "Coverage Fail: Javascript coverage was less than #{conf}%. It was #{coverage_pc}%." if conf && coverage_pc < conf.to_i
      end
    end

    def instrument folder, instrumented_sub_dir
      return if !File.directory? folder
      FileUtils.mkdir_p instrumented_sub_dir
      puts "Locating jscoverage..."
      system "which jscoverage"
      puts "Instrumenting JS files..."
      jsc_status = system "jscoverage -v #{folder} #{instrumented_sub_dir}"
      if jsc_status != true
        puts "jscoverage failed with status '#{jsc_status}'. Is jscoverage on your path? Path follows:"
        system "echo $PATH"
        puts "Result of calling jscoverage with no arguments follows:"
        system "jscoverage"
        fail "Unable to use jscoverage"
      end
    end
  end

  module Jasmine
    module Coverage
      @resources
      @output_dir
      @warnings

      def self.resources= resources
        @resources = resources
      end

      def self.resources
        @resources
      end

      def self.output_dir= output_dir
        @output_dir = output_dir
      end

      def self.output_dir
        @output_dir
      end

      def self.warnings= warnings
        @warnings = warnings
      end

      def self.warnings
        @warnings
      end
    end
  end

end
