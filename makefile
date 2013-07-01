COFFEE_FILES = $(shell find ./src -type f -name '*.coffee')

test:
	TEST_ROOT="src" ./node_modules/.bin/mocha

test-coverage:
	$(MAKE) clean
	$(MAKE) src-coverage
	mkdir -p ./test/report
	TEST_ROOT="src-coverage" ./node_modules/.bin/mocha --reporter html-cov > ./test/report/coverage.html

lib: $(COFFEE_FILES)
	./node_modules/.bin/coffee -co lib src

src-coverage: $(COFFEE_FILES)
	if ! [ -d node_modules/visionmedia-jscoverage ]; then npm install visionmedia-jscoverage; fi
	$(MAKE) lib
	./node_modules/visionmedia-jscoverage/jscoverage lib src-coverage

clean:
	rm -rf ./src-coverage
	rm -rf ./lib
	rm -rf ./test/report

.PHONY: test test-coverage clean
