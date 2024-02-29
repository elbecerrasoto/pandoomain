CONFIG=tests/config.yaml
SNAKEMAKE=snakemake --cores all --configfile $(CONFIG)


.PHONY test-dry:
test-dry:
	$(SNAKEMAKE) -np


.PHONY test:
test:
	$(SNAKEMAKE)


.PHONY test-fast:
test-fast:
	$(SNAKEMAKE) -- tests/results/blasts.faa
.PHONY test-mtime:


test-mtime:
	$(SNAKEMAKE) --rerun-triggers mtime


.PHONY style:
style:
	snakefmt .
	black .
	/usr/bin/Rscript -e 'styler::style_dir(".")'
	isort .
	isort workflow/Snakefile


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
