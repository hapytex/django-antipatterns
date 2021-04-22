plants = $(shell ls *.puml)
svgs = $(plants:%.puml=%.svg)
svgsz = $(svgs:%.svg=%.svgz)

all: $(svgs) $(svgsz)

%.svgz: %.svg
	gzip -f -k -S z "$<"

%.svg: %.puml skin.pu
	plantuml -p -config skin.pu -tsvg < "$<" | scour > "$@"
