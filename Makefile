markdowns = $(shell ls antipatterns/*.md)
outpdf = $(markdowns:antipatterns/%.md=out_/%.html)

all: out_ $(outpdf)
out_ :
	mkdir -p out_
out_/%.html: antipatterns/%.md Makefile
	pandoc -s -t html -c 'https://raw.githubusercontent.com/sindresorhus/github-markdown-css/gh-pages/github-markdown.css' --highlight-style haddock -o "$@" "$<"
