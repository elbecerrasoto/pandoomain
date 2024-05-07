SHELL = /usr/bin/bash

CORES = all
CONFIG = tests/config.yaml
ISCAN_VERSION = 5.67-99.0
CACHE = ~/.local/snakemake

SETUP_CACHE = mkdir -p $(CACHE) &&\
              export SNAKEMAKE_OUTPUT_CACHE=$(CACHE)

SNAKEMAKE = $(SETUP_CACHE) &&\
            snakemake --cores $(CORES)\
                      --configfile $(CONFIG)\
                      --cache

RESULTS = tests/results

GENOMES = tests/genomes.txt
GENOMES_MESSY = tests/genomes_messy.txt

SVGS = dag.svg filegraph.svg rulegraph.svg
CLEAN = .snakemake $(SVGS) $(RESULTS) $(GENOMES)

ISCAN_DATA = ~/.local/share
ISCAN_BIN = ~/.local/bin/interproscan.sh


.PHONY test-dry:
test-dry: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) -np


.PHONY test:
test: $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE)


.PHONY test-offline:
test-offline: $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --config offline=true


.PHONY test-mtime:
test-mtime: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --rerun-triggers mtime


.PHONY tree-results:
tree-results: $(GENOMES) $(CONFIG)
	tree -a $(RESULTS)


.PHONY clean-cache:
clean-cache:
	rm -rf $(CACHE)/*


.PHONY install-iscan:
install-iscan: utils/install_iscan.py
	@printf "To install remove --dry-run option from script.\n\n"
	$< --target $(ISCAN_VERSION) --data $(ISCAN_DATA) --bin $(ISCAN_BIN) --dry-run


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
	$(SNAKEMAKE) --dag       | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --rulegraph | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --filegraph | dot -Tsvg > filegraph.svg


.PHONY clean:
clean:
	@rm -rf $(CLEAN)
	git clean -d -n
	@printf "\nTo remove untracked files run:\ngit clean -d -f\n"
	@printf "tests/data has to be deleted manually:\nrm -r $(CACHE)"
