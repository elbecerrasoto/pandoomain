SHELL = /usr/bin/bash

SNAKEFILE = workflow/Snakefile

CORES = all
ISCAN_VERSION = 5.72-103.0
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
PNGS = dag.png filegraph.png rulegraph.png
CLEAN = .snakemake $(SVGS) $(PNGS) $(RESULTS)

ISCAN_DATA = ~/.local/share
ISCAN_BIN = ~/.local/bin/interproscan.sh


.PHONY test-dry:
test-dry: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG) -np


.PHONY test-empty:
test-empty: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG_EMPTY)


.PHONY test:
test: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	@printf "Before looking for errors, clean-cache.\n\n"
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG)


.PHONY test-offline:
test-offline: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG) --config offline=true


.PHONY test-mtime:
test-mtime: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	rm -rf $(RESULTS)
	$(SNAKEMAKE) --configfile $(CONFIG) --rerun-triggers mtime


.PHONY debug:
debug: $(SNAKEFILE) (GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) -np --print-compilation > smkC.py 2> smkC.err
	$(SNAKEMAKE) --configfile $(CONFIG) -np --cores 1 > debug.out 2> debug.err


.PHONY install-iscan:
install-iscan: utils/install_iscan.py
	@printf "To install remove --dry-run option from script.\n\n"
	$< --reinstall --target $(ISCAN_VERSION) --data $(ISCAN_DATA) --bin $(ISCAN_BIN) --dry-run


.PHONY style:
style:
	snakefmt .
	black .
	/usr/bin/Rscript -e 'styler::style_dir("workflow")'
	/usr/bin/Rscript -e 'styler::style_dir("utils")'
	isort --float-to-top -- utils workflow workflow/Snakefile
	isort --float-to-top --ext smk -- utils workflow


$(SVGS): $(SNAKEFILE) $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) --dag       | dot -Tsvg > dag.svg
	$(SNAKEMAKE) --configfile $(CONFIG) --rulegraph | dot -Tsvg > rulegraph.svg
	$(SNAKEMAKE) --configfile $(CONFIG) --filegraph | dot -Tsvg > filegraph.svg


$(PNGS): $(SVGS) $(GENOMES) $(CONFIG)
	parallel convert -background none -size 6000x6000 {} {.}.png ::: $(SVGS) 


report.html: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) --report


.PHONY git-config:
git-config:
	git config --global alias.root 'rev-parse --show-toplevel'
	git config push.autoSetupRemote true


.PHONY clean:
clean:
	@rm -rf $(CLEAN)
	git clean -d -n
	@printf "\nTo remove untracked files:\ngit clean -d -f\n"
	@printf "To remove cache data:\nmake clean-cache $(CACHE)"


.PHONY clean-cache:
clean-cache:
	rm -rf $(CACHE)/*
