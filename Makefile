CONFIG = tests/config-slow.yaml

SNAKEMAKE = snakemake --cores all --configfile $(CONFIG) --cache interproscan_tsv

RESULTS = tests/results

GENOMES = tests/genomes.txt
GENOMES_MESSY = tests/genomes_messy.txt

SVGS = dag.svg filegraph.svg rulegraph.svg
CLEAN = .snakemake $(SVGS) $(RESULTS) $(GENOMES)

.PHONY test-dry:
test-dry: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) -np


.PHONY test:
test: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE)


.PHONY test-mtime:
test-mtime: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --rerun-triggers mtime


.PHONY tree-results:
tree-results: $(GENOMES) $(CONFIG)
	tree -a $(RESULTS)


.PHONY install-iscan:
install-iscan: utils/install_iscan.py
	@printf "To install remove --dry-run option from script.\n\n"
	$< --target 5.67-99.0 --data ~/.local/share --bin ~/.local/bin/interproscan.sh --dry-run


$(GENOMES): $(GENOMES_MESSY)
	utils/deduplicate_accessions.R $< 2> /dev/null > $@


.PHONY style:
style:
	snakefmt .
	black .
	/usr/bin/Rscript -e 'styler::style_dir(".")'
	isort .
	isort workflow/Snakefile


.PHONY dag:
dag: $(GENOMES)
	$(SNAKEMAKE) --dag | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --rulegraph      | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --filegraph      | dot -Tsvg > filegraph.svg


.PHONY clean:
clean:
	@rm -rf $(CLEAN)
	git clean -d -n
	@printf "\nTo remove untracked files run:\ngit clean -d -f\n"
	@printf "tests/data has to be deleted manually:\nrm -r $(CACHE)"
