SHELL = /usr/bin/bash

SNAKEFILE = workflow/Snakefile

CORES = all
ISCAN_VERSION = 5.73-104.0
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

FIG_DIR = graphs
FIG_NAMES = dag filegraph rulegraph
SVGS = $(foreach i,$(FIG_NAMES),$(FIG_DIR)/$(i).svg)
PNGS = $(foreach i,$(FIG_NAMES),$(FIG_DIR)/$(i).png)

CLEAN = .snakemake $(FIG_DIR) $(RESULTS)

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
debug: $(SNAKEFILE) $(GENOMES) $(CONFIG)
	$(SNAKEMAKE) --configfile $(CONFIG) -np --print-compilation >| debug.py
	black debug.py
	bat --style=plain debug.py

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
	mkdir -p $(FIG_DIR)
	$(SNAKEMAKE) --configfile $(CONFIG) --dag       | dot -Tsvg > $(FIG_DIR)/dag.svg
	$(SNAKEMAKE) --configfile $(CONFIG) --filegraph | dot -Tsvg > $(FIG_DIR)/filegraph.svg
	$(SNAKEMAKE) --configfile $(CONFIG) --rulegraph | dot -Tsvg > $(FIG_DIR)/rulegraph.svg


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
	@printf "\nTo remove untracked files:\n"
	@printf "    + git clean -d -f\n"
	@printf "\nTo remove cache data\n"
	@printf "at $(CACHE) run:\n"
	@printf "    + make clean-cache\n"


.PHONY clean-cache:
clean-cache:
	rm -rf $(CACHE)/*

# Debugging print
# .PHONY print-%:
# Makefile:126: *** mixed implicit and normal rules: deprecated syntax
print-%: ; @echo $* = $($*)

SERVER = https://github.com/conda-forge/miniforge/releases/download/24.11.3-0

MINIFORGE = Miniforge3-24.11.3-0-Linux-x86_64.sh
LINK_MINIFORGE = $(SERVER)/$(MINIFORGE)

SHA256 = $(MINIFORGE).sha256
LINK_SHA256 = $(SERVER)/$(SHA256)

$(MINIFORGE):
	wget '$(LINK_MINIFORGE)'
	wget '$(LINK_SHA256)'
	sha256sum -c '$(SHA256)'


.PHONY install-mamba:
install-mamba: $(MINIFORGE)
	bash $(MINIFORGE) -u

