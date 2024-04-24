CONFIG = tests/config.yaml
CONFIG_SLOW = tests/config-slow.yaml

SNAKEMAKE = snakemake --cores all --configfile $(CONFIG) --rerun-triggers mtime
SNAKEMAKE_SLOW = snakemake --cores all --configfile $(CONFIG_SLOW)

RESULTS_DIR = tests/results

GENOMES = tests/genomes.txt
GENOMES_MESSY = tests/genomes_messy.txt

GENOMES_CACHE = tests/data
GENOMES_OUT_DIR = $(RESULTS_DIR)/genomes

GENOMES_IDS = GCF_001286845.1 GCF_001286885.1

PIDS = WP_072173795.1 WP_072173796.1

C_GREP = 24

SVGS = dag.svg filegraph.svg rulegraph.svg
CLEAN = .snakemake $(SVGS) $(RESULTS_DIR) $(GENOMES)

SENTINEL_CACHE = $(GENOMES_CACHE)/.sentinel_cache
SENTINEL_LINK = $(GENOMES_OUT_DIR)/.sentinel_link

ISCAN_CACHE = $(GENOMES_CACHE)/iscan.tsv
ISCAN_LINK = $(RESULTS_DIR)/iscan.tsv

.PHONY test-dry:
test-dry: $(GENOMES) $(SENTINEL_LINK) $(CONFIG) $(ISCAN_LINK)
	make rm-setup-test
	$(SNAKEMAKE) -np


.PHONY test:
test: $(GENOMES) $(SENTINEL_LINK) $(CONFIG) $(ISCAN_LINK)
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
	utils/generate_genomes.py \
							--cache-dir $(GENOMES_CACHE) \
							--link-dir $(GENOMES_OUT_DIR) \
							--genomes $(GENOMES_IDS)
	touch $(SENTINEL_LINK)


$(SENTINEL_CACHE):
	utils/generate_cache.py \
							--C-grep $(C_GREP) \
							--config $(CONFIG_SLOW) \
							--cache-dir $(GENOMES_CACHE) \
							--genomes-dir $(GENOMES_OUT_DIR) \
							--genomes $(GENOMES_IDS) \
							--pids $(PIDS)
	touch $(SENTINEL_CACHE)


$(SEN_ISCAN_CACHE): $(SENTINEL_LINK) $(GENOMES)
	$(SNAKEMAKE) -- $(ISCAN_LINK)
	mv $(ISCAN_LINK) $(GENOMES_CACHE)
	$(SEN_ISCAN_CACHE)


$(SEN_ISCAN_LINK): $(SEN_ISCAN_CACHE)
	rm $(ISCAN_LINK)
	mkdir -p $(RESULTS_DIR)
	ln -s `readlink -n -f $(SEN_ISCAN_CACHE)` $(RESULTS_DIR)
	touch $(SEN_ISCAN_LINK)


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
	@if [[ -d $(RESULTS_DIR) ]]; then \
		fd -HI -t f --exclude "{*.1.faa,*.1.gff,iscan.tsv}" '.' $(RESULTS_DIR) --exec rm; \
	fi


.PHONY clean:
clean:
	@rm -rf $(CLEAN)
	git clean -d -n
	@printf "\nTo remove untracked files run:\ngit clean -d -f\n"
	@printf "tests/data has to be deleted manually:\nrm -r tests/data"
