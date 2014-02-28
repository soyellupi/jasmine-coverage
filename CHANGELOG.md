# CHANGELOG

## 0.3.1

 * Locking Rails version to 3.2.x

## 0.3.0

 * Adding checks to see if the needed gem jasmine-headless-webkit had compiled correctly.

## 0.2.9

 * Locking jasmine-core version to 1.3.1, as 2.0.0 had breaking changes.

## 0.2.8

 * Adding better error if you try and run two tests simultaneously (which crashes the shared virtual frame buffer)

## 0.2.7

 * Accepted that jasmine-headless-coverage pull request will never be accepted, so cut own gem
 * Merged in jasmine-headless-coverage fix for QT 4.8


## 0.2.6

 * Adding license (MIT)
 * Cleaning out the old test rig folder before a new run


## 0.2.5

 * Inverted JASMINE_COVERAGE_KEEP_TEST_RIG default. It now keeps it unless specified as false.
 * Added test output to console
 * Corrected 0 instruction files to show 100% coverage
 * Check file write permissions before writing reports


## 0.2.4

 * Corrected JS logging call
 * Merged nader-jw work to allow warnings and path settings
 * Added JASMINE_COVERAGE_WARNINGS
 * Added JS_SRC_PATH

