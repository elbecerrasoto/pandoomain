SHELL = /usr/bin/bash

CORES = all
CONFIG = tests/config.yaml
ISCAN_VERSION = 5.68-100.0
CACHE = ~/.local/snakemake

SETUP_CACHE = mkdir -p $(CACHE) &&\
              export SNAKEMAKE_OUTPUT_CACHE=$(CACHE)

SNAKEMAKE = $(SETUP_CACHE) &&\
            snakemake --cores $(CORES)\
                      --configfile $(CONFIG)\
                      --cache

RESULTS = tests/results

GENOMES_MESSY = tests/genomes_messy.txt

SVGS = dag.svg filegraph.svg rulegraph.svg
CLEAN = .snakemake $(SVGS) $(RESULTS)

ISCAN_DATA = ~/.local/share
ISCAN_BIN = ~/.local/bin/interproscan.sh


.PHONY test-dry:
test-dry: $(GENOMES_MESSY) $(CONFIG)
	$(SNAKEMAKE) -np


.PHONY test:
test: $(GENOMES_MESSY) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE)


.PHONY test-offline:
test-offline: $(GENOMES_MESSY) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --config offline=true


.PHONY test-mtime:
test-mtime: $(GENOMES_MESSY) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --rerun-triggers mtime


.PHONY tree-results:
tree-results:
	tree -a $(RESULTS)


.PHONY debug:
debug: $(GENOMES_MESSY) $(CONFIG)
	$(SNAKEMAKE) -np --print-compilation > smkC.py 2> smkC.err
	$(SNAKEMAKE) -np --cores 1 > debug.out 2> debug.err


.PHONY debug-offline:
debug-offline: $(GENOMES_MESSY) $(CONFIG)
	$(SNAKEMAKE) -np --print-compilation --config offline=true > smkC.py 2> smkC.err
	$(SNAKEMAKE) -np --cores 1 --config offline=true > debug.out 2> debug.err


.PHONY clean-cache:
clean-cache:
	rm -rf $(CACHE)/*


.PHONY install-iscan:
install-iscan: utils/install_iscan.py
	@printf "To install remove --dry-run option from script.\n\n"
	$< --target $(ISCAN_VERSION) --data $(ISCAN_DATA) --bin $(ISCAN_BIN) --dry-run


.PHONY style:
style:
	snakefmt .
	black .
	/usr/bin/Rscript -e 'styler::style_dir(".")'
	isort --float-to-top -- utils/ workflow/ workflow/Snakefile
	isort --float-to-top --ext smk -- utils/ workflow/

$(SVGS): $(GENOMES_MESSY) $(CONFIG)
	$(SNAKEMAKE) --dag       | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --rulegraph | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --filegraph | dot -Tsvg > filegraph.svg


report.html: $(GENOMES_MESSY) $(CONFIG)
	$(SNAKEMAKE) --report


.PHONY clean:
clean:
	@rm -rf $(CLEAN)
	git clean -d -n
	@printf "\nTo remove untracked files run:\ngit clean -d -f\n"
	@printf "Cache data has to be deleted manually:\nrm -r $(CACHE)"


.PHONY git-config:
git-config:
	git config --global alias.root 'rev-parse --show-toplevel'
	git config push.autoSetupRemote true
