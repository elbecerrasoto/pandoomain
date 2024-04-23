CONFIG = tests/config.yaml
CONFIG_SLOW = tests/config-slow.yaml

SNAKEMAKE = snakemake --cores all --configfile $(CONFIG)
SNAKEMAKE_SLOW = snakemake --cores all --configfile $(CONFIG_SLOW)

RESULTS_DIR = tests/results

GENOMES = tests/genomes.txt
GENOMES_MESSY = tests/genomes_messy.txt

GENOMES_OUT_DIR = $(RESULTS_DIR)/genomes
GENOMES_CACHE = tests/data

GENOMES_IDS = GCF_001286845.1 GCF_001286885.1

PIDs = WP_072173795.1 WP_072173796.1

C_GREP = 24

SVGS = dag.svg filegraph.svg rulegraph.svg
CLEAN = .snakemake $(SVGS) $(RESULTS_DIR) $(GENOMES)

SENTINEL_CACHE = $(GENOMES_CACHE)/.sentinel_cache
SENTINEL_LINK_CACHE = $(GENOMES_OUT_DIR)/.sentinel_link


.PHONY test-dry:
test-dry: $(GENOMES) $(SENTINEL_LINK) $(CONFIG)
	make rm-setup-test
	$(SNAKEMAKE) -np


.PHONY test:
test: $(GENOMES) $(SENTINEL_LINK) $(CONFIG)
	make rm-setup-test
	$(SNAKEMAKE)


.PHONY test-slow:
test-slow: $(GENOMES) $(CONFIG_SLOW)
	$(SNAKEMAKE_SLOW) --forceall


.PHONY test-mtime:
test-mtime: $(GENOMES) $(CONFIG_SLOW)
	$(SNAKEMAKE_SLOW) --rerun-triggers mtime


.PHONY tree-results:
tree-results: $(GENOMES) $(CONFIG_SLOW)
	tree -a $(RESULTS_DIR)


$(GENOMES): $(GENOMES_MESSY)
	utils/deduplicate_accessions.R $< 2> /dev/null > $@


$(SENTINEL_LINK): $(SENTINEL_CACHE)
	utils/generate_test_genomes.py -- $(CACHE_GFFs) $(CACHE_FAAs)


$(SENTINEL_CACHE):
	utils/generate_cache_genomes.py --C-grep $(C_GREP) --gffs $(GFFs) --faas $(FAAs) --pids $(PIDs)


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


.PHONY rm-setup-test:
rm-setup-test:
	fd -HI -t f --exclude "*.1.{faa,gff}" '.' $(RESULTS_DIR) --exec rm


.PHONY clean:
clean:
	rm -rf $(CLEAN)
	git clean -d -n
	printf "\nTo remove untracked files run:\ngit clean -d -f\n"
