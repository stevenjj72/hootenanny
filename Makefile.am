
# A quick search didn't show the right config macro, I'm sure it is out there...
TAR=tar
EXCLUDE_DIRS=grep -E -v ".*/$$"
confdir=$(prefix)/conf
plugindir=$(prefix)/plugins

always:

# Don't try to build these, the old makefile will do it.
bin/hoot:
bin/hoot.bin:

osmapidb:
	$(MAKE) -f Makefile.hoot osmapidb

archive:
	$(MAKE) -f Makefile.hoot dist

clean-db:
	$(MAKE) -f Makefile.hoot clean-db

clean-all:
	$(MAKE) -f Makefile.hoot clean-all

clean-coverage:
	$(MAKE) -f Makefile.hoot clean-coverage

coverage:
	$(MAKE) -f Makefile.hoot coverage

core:
	$(MAKE) -f Makefile.hoot core

core-coverage:
	$(MAKE) -f Makefile.hoot core-coverage

eclipse:
	$(MAKE) -f Makefile.hoot eclipse

licenses:
	$(MAKE) -f Makefile.hoot licenses

docs: always
	$(MAKE) -f Makefile.hoot docs

requirements:
	cd docs; $(MAKE) requirements

tmp/schema.png:
	$(MAKE) -f Makefile.hoot tmp/schema.png

help:
	@echo "help                    - This help message."
	@echo "archive                 - Make a distributable tarball."
	@echo "build                   - Build all source and populated/upgrade the DB if necessary."
	@echo "check                   - Run all the tests that should be run before commit."
	@echo "clean                   - Clean out all binaries. This will not modify the DB."
	@echo "clean-all               - Clean out all binaries and remove all tables from the DB defined in liquibase.properties"
	@echo "clean-coverage          - Remove all test code coverage report output."
	@echo "clean-db                - Remove all tables from the DB defined in liquibase.properties"
	@echo "core                    - Build just the core without any UI elements"
	@echo "core-coverage           - If configured '--with-coverage', then creates coverage reports for the core."
	@echo "coverage                - If configured '--with-coverage', then creates test coverage reports."
	@echo "docs                    - Build all project documentation."
	@echo "dist                    - Make a distributable tarball."
	@echo "eclipse                 - If configured '--with-services', then, builds Eclipse IDE project files."
	@echo "osmapidb                - If configured '--with-services', then builds a clean copy of an OSM API database."
	@echo "plugins-test            - Run the mocha plugins tests.  Should take less than five minutes."
	@echo "services-build          - If configured '--with-services', then builds just the web services source."
	@echo "services-clean          - If configured '--with-services', then cleans just the web services binaries. This will not modify the DB."
	@echo "services-clean-coverage - If configured '--with-services', then removes just the web services test code coverage report output."
	@echo "services-coverage       - If configured '--with-services' and '--with-coverage', then creates just the web services coverage report."
	@echo "services-docs           - If configured '--with-services', then builds just the web services documentation."
	@echo "services-test           - If configured '--with-services', then runs the web services slow tests.  Should take five to ten minutes."
	@echo "services-test-all       - If configured '--with-services', then runs the web services glacial tests.  Should take five to ten minutes."
	@echo "test                    - Run slow tests.  Should take no more than five to ten minutes."
	@echo "test-all                - Run all tests.  Could take more than ten minutes."
	@echo "test-quick              - Run quick tests.  Should take less than five minutes."
	@echo "ui-build                - Build the web UI js/css dist.  Must enable --with-services configuration options."
	@echo "ui-test                 - Run user interface tests.  May take several minutes.  Must enable --with-uitests and --with-services configuration options."
	@echo "ui2x-test               - Run user interface tests on ui2x.  May take several minutes.  Must enable --with-uitests and --with-services configuration options."
	@echo "ui-coverage             - Generate coverage reports for mocha and cucumber user interface tests.  May take several minutes.  Must enable --with-uitests and --with-services configuration options."
	@echo "ui-clean-coverage       - Removes the coverage reports for mocha and cucumber user interface tests."
	@echo "ui2x-build              - Build the web UI 2.0 js/css dist.  Must enable --with-services configuration options."

test:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot test

test-all:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot test-all

test-all-no-core:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot test-all-no-core

test-all-core:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot test-all-core

test-quick:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot test-quick

services-test:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot services-test

services-test-all:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot services-test-all

ui-build:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot ui-build

ui-test:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot ui-test
	
ui2x-test:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot ui2x-test

ui-coverage:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot ui-coverage

ui-clean-coverage:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot ui-clean-coverage

ui2x-build:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot ui2x-build

plugins-test:
	scripts/HootEnv.sh $(MAKE) -f Makefile.hoot plugins-test

services-build:
	$(MAKE) -f Makefile.hoot services-build

services-docs:
	$(MAKE) -f Makefile.hoot services-docs

services-clean:
	$(MAKE) -f Makefile.hoot services-clean

services-clean-db:
	$(MAKE) -f Makefile.hoot services-clean-db

services-clean-coverage:
	$(MAKE) -f Makefile.hoot services-clean-coverage

services-coverage:
	$(MAKE) -f Makefile.hoot services-coverage

# Use some tar fanciness to grab all the files in conf, plugins, translations and scripts
install-other:
	mkdir -p tmp
	$(TAR) cf tmp/other.tar conf plugins scripts translations rules
	mkdir -p $(localstatedir)
	cat tmp/other.tar | $(TAR) xv -C $(localstatedir)
	rm -f tmp/other.tar
	mkdir -p $(docdir)
	cp LICENSE README.md docs/*.pdf $(docdir)
	mkdir -p $(sysconfdir)/profile.d/
	mkdir -p $(sysconfdir)/asciidoc/filters/
	cp -R docs/filters/* $(sysconfdir)/asciidoc/filters/
	echo "export HOOT_HOME=$(localstatedir)" > $(sysconfdir)/profile.d/hootenanny.sh
	mkdir -p $(includedir)
	export HOOT_HOME=`pwd`; \
	cd $$HOOT_HOME/hoot-core/src/main/cpp/; \
	(find . -name '*.h' -print | tar --create --files-from -) | (cd $(includedir) && tar xvfp -); \
	cd $$HOOT_HOME/hoot-js/src/main/cpp; \
	(find . -name '*.h' -print | tar --create --files-from -) | (cd $(includedir) && tar xvfp -); \
	cd $$HOOT_HOME/hoot-rnd/src/main/cpp/; \
	(find . -name '*.h' -print | tar --create --files-from -) | (cd $(includedir) && tar xvfp -)

install-data-local: install-other

install-exec-local:
	mkdir -p $(bindir) $(libdir) $(confdir)
	$(INSTALL) bin/* $(bindir)
	rm $(bindir)/HootEnv.sh
	mkdir -p $(localstatedir)/bin/
	cp bin/HootEnv.sh $(localstatedir)/bin/
	cp -l $(localstatedir)/bin/HootEnv.sh $(bindir)
	cp -a lib/* $(libdir)

# Clean out all install files and then remove the empty directories.
uninstall-local:

SUBDIRS=stub
