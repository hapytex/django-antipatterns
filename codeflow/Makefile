plants = $(shell ls *.puml)
svgs = $(plants:%.puml=%.svg)

all: $(svgs)

%.svg: %.puml skin.pu
	plantuml -p -config skin.pu -tsvg < "$<" | scour > "$@"
