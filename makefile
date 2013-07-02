COFFEE_FILES = $(shell find ./src -type f -name '*.coffee')

test:
	TEST_ROOT="src" ./node_modules/.bin/mocha

test-coverage:
	$(MAKE) clean
	$(MAKE) lib
	mkdir -p ./artifacts/tests
	TEST_ROOT="lib" ./node_modules/.bin/mocha --require blanket --reporter html-cov > ./artifacts/tests/coverage.html

travis:
	$(MAKE) clean
	$(MAKE) lib
	mkdir -p ./artifacts/tests
	TEST_ROOT="lib" ./node_modules/.bin/mocha --require blanket --reporter mocha-lcov-reporter | ./node_modules/.bin/coveralls

lib: $(COFFEE_FILES)
	./node_modules/.bin/coffee -co lib src

clean:
	rm -rf ./lib
	rm -rf ./artifacts

.PHONY: test test-coverage travis clean
