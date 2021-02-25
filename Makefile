markdowns = $(shell ls antipatterns/*.md patterns/*.md troubleshooting/*.md)
outhtml = $(markdowns:%.md=out_/%.html)
style = # https://bootswatch.com/4/slate/bootstrap.css  # 'https://raw.githubusercontent.com/sindresorhus/github-markdown-css/gh-pages/github-markdown.css' 

all: out_ out_/antipatterns out_/patterns out_/troubleshooting $(outhtml) out_/index.html out_/favicon.ico out_/sitemap.xml
out_ :
	mkdir -p out_
	ln -f site/* out_
index.md : toc.sh $(outhtml)
	bash toc.sh > "$@"
out_/sitemap.xml:
	git clone https://github.com/knyzorg/Sitemap-Generator-Crawler.git sitemap_
	php sitemap_/sitemap.php file="$@" site=https://www.django-antipatterns.com
out_/%.html: %.md Makefile templates/easy_template.html
	printf "<!DOCTYPE html><meta charset=\"utf-8\"><title>Redirecting to /$(@:out_/%=%)</title><meta http-equiv=\"refresh\" content=\"0; URL=/$(@:out_/%=%)\"><link rel=\"canonical\" href=\"/$(@:out_/%=%)\">" "$@" > $(subst -,_,$@)
	pandoc -s -f markdown -t html --template=templates/easy_template.html -c "${style}" --highlight-style haddock -o "$@" "$<"

out_/%.ico : media/%.ico
	ln "$<" "$@"

out_/%:
	mkdir -p "$@"

hunspell:antipatterns/*.md patterns/*.md troubleshooting/*.md
	hunspell -H "$<"
