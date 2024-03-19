CONFIG=tests/config.yaml
GENOMES=tests/genomes.txt
SNAKEMAKE=snakemake --cores all --configfile $(CONFIG)

.PHONY test-dry:
test-dry: $(GENOMES)
	$(SNAKEMAKE) -np


$(GENOMES): tests/genomes_messy.txt
	utils/deduplicate_accessions.R $< 2> /dev/null > $@


.PHONY test:
test: $(GENOMES)
	$(SNAKEMAKE)


.PHONY test-fast:
test-fast: $(GENOMES)
	$(SNAKEMAKE) -- tests/results/blasts.faa
.PHONY test-mtime:


test-mtime: $(GENOMES)
	$(SNAKEMAKE) --rerun-triggers mtime


.PHONY style:
style:
	snakefmt .
	black .
	/usr/bin/Rscript -e 'styler::style_dir(".")'
	isort .
	isort workflow/Snakefile


.PHONY dag:
dag: $(GENOMES)
	$(SNAKEMAKE) --forceall --dag | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --rulegraph      | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --filegraph      | dot -Tsvg > filegraph.svg


.PHONY clean:
clean:
	rm -rf tests/results/
	rm -rf .snakemake/
	rm -rf dag.svg rulegraph.svg filegraph.svg
	rm -rf tests/genomes.txt
