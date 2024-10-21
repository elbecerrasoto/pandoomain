SHELL = /usr/bin/bash

CORES = all
ISCAN_VERSION = 5.70-102.0
CACHE = ~/.local/snakemake

SETUP_CACHE = mkdir -p $(CACHE) &&\
              export SNAKEMAKE_OUTPUT_CACHE=$(CACHE)

SNAKEMAKE = $(SETUP_CACHE) &&\
            snakemake --cores $(CORES)\
                      --cache\
					  --printshellcmds

CONFIG = tests/config.yaml
CONFIG_EMPTY = tests/config_empty.yaml

GENOMES = tests/genomes.txt
GENOMES_EMPTY = tests/genomes_empty.txt

RESULTS = tests/results

SVGS = dag.svg filegraph.svg rulegraph.svg
CLEAN = .snakemake $(SVGS) $(RESULTS)

ISCAN_DATA = ~/.local/share
ISCAN_BIN = ~/.local/bin/interproscan.sh


.PHONY test-dry:
test-dry: $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG) -np


.PHONY test-empty:
test-empty: $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG_EMPTY)


.PHONY test:
test: $(GENOMES) $(CONFIG)
	@printf "Before looking for errors, clean-cache.\n\n"
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG)


.PHONY test-offline:
test-offline: $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG) --config offline=true


.PHONY test-mtime:
test-mtime: $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG) --rerun-triggers mtime


.PHONY debug:
debug: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) -np --print-compilation > smkC.py 2> smkC.err
	$(SNAKEMAKE) --configfile $(CONFIG) -np --cores 1 > debug.out 2> debug.err


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
	/usr/bin/Rscript -e 'styler::style_dir("workflow")'
	/usr/bin/Rscript -e 'styler::style_dir("utils")'
	isort --float-to-top -- utils workflow workflow/Snakefile
	isort --float-to-top --ext smk -- utils workflow


$(SVGS): $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) --dag       | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --configfile $(CONFIG) --rulegraph | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --configfile $(CONFIG) --filegraph | dot -Tsvg > filegraph.svg


report.html: $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) --report


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
