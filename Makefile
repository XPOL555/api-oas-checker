#
# Generate a browser bundle
#
#
TMPDIR := $(shell mktemp  -u /tmp/fooXXXXXX)

all: setup bundle

# Create the web pages in bundle/
bundle: bundle/js/bootstrap-italia.min.js copy_public bundle/out.js index.html spectral.yml

bundle/out.js: public/js/bundle.js package.json setup
	npx browserify --outfile bundle/out.js --standalone api_oas_checker public/js/bundle.js

gh-pages: bundle rules
	rm css js asset svg -fr
	git clone . $(TMPDIR) -b gh-pages
	cp -r bundle/* $(TMPDIR)
	git -C $(TMPDIR) add *
	git -C $(TMPDIR) -c user.name="gh-pages bot" -c user.email="gh-bot@example.it" \
		commit -m "Script updating gh-pages from $(shell git rev-parse short HEAD). [ci skip]"
	git -C $(TMPDIR) push -q origin gh-pages
	rm $(TMPDIR) -fr

bundle/js/bootstrap-italia.min.js:
	cp -r node_modules/bootstrap-italia/dist/* bundle/

copy_public:
	cp public/js/* bundle/js/
	cp public/css/* bundle/css/
	cp -r public/icons bundle/icons/
	cp index.html spectral.yml bundle

# Merge all rules into spectral.yml
rules: spectral.yml

spectral.yml: ./rules/
	cat ./rules/rules-template.yml > spectral.yml
	./rules/merge-yaml >> spectral.yml

clean:
	# removing compiled bundle and node_modules
	rm -rf bundle node_modules

#
# Preparation goals
#
/usr/local/lib/node_modules/api-oas-checker: package.json
	npm link api-oas-checker

setup: /usr/local/lib/node_modules/api-oas-checker package.json
	npm install .
	mkdir -p bundle

t:
	spectral lint rules/$(RULE)-test.yml -r rules/$(RULE).yml


test:
	# once you filter out "ko" strings, you should have no "  error  "s.
	@for f in $(shell ls rules/*-test.yml); do \
		spectral lint $$f -r `echo $$f | sed -e 's,-test,,'` ; \
		done \
		| grep -v ko | grep '  error  ' && exit 1 || exit 0
	
	
