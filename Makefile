CONFIG=tests/config.yaml
SNAKEMAKE=snakemake --cores all --configfile $(CONFIG)


.PHONY dry-test:
dry-test:
	$(SNAKEMAKE) -np


.PHONY test:
test:
	$(SNAKEMAKE)


.PHONY style:
style:
	snakefmt .
	black .
	/usr/bin/Rscript -e 'styler::style_dir(".")'


.PHONY dag:
dag:
	$(SNAKEMAKE) --forceall --dag | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --rulegraph      | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --filegraph      | dot -Tsvg > filegraph.svg


.PHONY clean:
clean:
	rm -rf tests/results/
	rm -rf .snakemake/
	rm -rf dag.svg rulegraph.svg filegraph.svg
