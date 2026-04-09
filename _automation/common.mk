# _automation/common.mk — shared Make logic for all FPGA projects
# Include this from project-level Makefiles only:
#   include $(shell git rev-parse --show-toplevel)/_automation/common.mk
#
# Do NOT add build logic to project Makefiles. All policy lives here.

# ── Environment check (must fire before any recipe) ───────────────────────────
ifndef DIAMOND_ENV_SOURCED
$(error Environment not initialized. Run: source _automation/env.sh)
endif

# ── Project identity (derived entirely from filesystem) ───────────────────────
PROJECT_DIR  := $(abspath $(CURDIR))
PROJECT_NAME := $(notdir $(PROJECT_DIR))
PRJ_DIR      := $(PROJECT_DIR)/prj
PROJECT_LDF  := $(PRJ_DIR)/$(PROJECT_NAME).ldf
AUTOMATION   := $(AUTOMATION_ROOT)
META         := $(PROJECT_DIR)/project.meta

# ── Validate project.meta exists ─────────────────────────────────────────────
ifeq ($(wildcard $(META)),)
$(error ERROR: project.meta not found in $(PROJECT_DIR))
endif

# ── Read hardware facts from project.meta ─────────────────────────────────────
DEVICE      := $(shell grep '^DEVICE='      $(META) | cut -d= -f2)
PACKAGE     := $(shell grep '^PACKAGE='     $(META) | cut -d= -f2)
SPEED       := $(shell grep '^SPEED='       $(META) | cut -d= -f2)
TOP_MODULE  := $(shell grep '^TOP_MODULE='  $(META) | cut -d= -f2)
TOP_TB      ?= $(TOP_MODULE)_tb

# ── Source discovery (evaluated at Make parse time) ───────────────────────────
RTL_SOURCES := $(shell cat $(PROJECT_DIR)/src/sources.f 2>/dev/null | \
    grep -v '^\s*\#' | grep -v '^\s*$$' | sed 's|^|$(PROJECT_DIR)/|')
TB_SOURCES  := $(shell cat $(PROJECT_DIR)/tb/tb_files.f 2>/dev/null | \
    grep -v '^\s*\#' | grep -v '^\s*$$' | sed 's|^|$(PROJECT_DIR)/|')
CONSTRAINTS := $(shell cat $(PROJECT_DIR)/syn/constraints.f 2>/dev/null | \
    grep -v '^\s*\#' | grep -v '^\s*$$' | sed 's|^|$(PROJECT_DIR)/|')

SYN_DEPS := $(RTL_SOURCES) $(CONSTRAINTS) $(META)
PAR_DEPS := $(PROJECT_DIR)/syn/out/.syn_done $(CONSTRAINTS)
SIM_DEPS := $(RTL_SOURCES) $(TB_SOURCES)

# ── Default goal ──────────────────────────────────────────────────────────────
.DEFAULT_GOAL := help

# ── Phony targets ─────────────────────────────────────────────────────────────
.PHONY: all syn par sim syn-gui par-gui sim-gui regen_ip \
        clean clean-syn clean-par help check-env create-project

# ── Environment check target ──────────────────────────────────────────────────
check-env:
ifndef DIAMOND_ENV_SOURCED
	$(error Environment not initialized. Run: source _automation/env.sh)
endif

# ── Project creation (idempotent — create_project.tcl skips if .ldf exists) ───
create-project: $(PROJECT_LDF)

$(PROJECT_LDF):
	@mkdir -p $(PRJ_DIR)
	@echo "Creating Diamond project: $(PROJECT_NAME)"
	@$(DIAMONDC) $(AUTOMATION)/tcl/create_project.tcl \
	    $(PRJ_DIR) $(PROJECT_NAME) $(DEVICE) $(PACKAGE) $(SPEED)

# ── Synthesis ─────────────────────────────────────────────────────────────────
$(PROJECT_DIR)/syn/out/.syn_done: $(SYN_DEPS)
	@mkdir -p $(PROJECT_DIR)/syn/logs $(PROJECT_DIR)/syn/out
	$(eval _SYN_LOG := $(PROJECT_DIR)/syn/logs/syn_$(shell date +%Y%m%d_%H%M%S).log)
	@echo "Running synthesis... Log: $(_SYN_LOG)"
	@$(DIAMONDC) $(AUTOMATION)/tcl/syn.tcl \
	    $(PROJECT_DIR) $(PROJECT_NAME) > $(_SYN_LOG) 2>&1 || \
	    (echo "--- last 40 lines of $(_SYN_LOG) ---"; \
	     tail -40 $(_SYN_LOG); exit 1)
	@touch $@
	@echo "Synthesis complete. Log: $(_SYN_LOG)"

syn: $(PROJECT_DIR)/syn/out/.syn_done

# ── Place and route ───────────────────────────────────────────────────────────
$(PROJECT_DIR)/par/out/.par_done: $(PAR_DEPS)
	@mkdir -p $(PROJECT_DIR)/par/logs $(PROJECT_DIR)/par/out
	$(eval _PAR_LOG := $(PROJECT_DIR)/par/logs/par_$(shell date +%Y%m%d_%H%M%S).log)
	@echo "Running place-and-route... Log: $(_PAR_LOG)"
	@$(DIAMONDC) $(AUTOMATION)/tcl/par.tcl \
	    $(PROJECT_DIR) $(PROJECT_NAME) > $(_PAR_LOG) 2>&1 || \
	    (echo "--- last 40 lines of $(_PAR_LOG) ---"; \
	     tail -40 $(_PAR_LOG); exit 1)
	@touch $@
	@echo "Place-and-route complete. Log: $(_PAR_LOG)"

par: $(PROJECT_DIR)/par/out/.par_done

# ── Simulation (headless Questa Sim — GUI must never open here) ───────────────
sim: check-env $(SIM_DEPS)
	@mkdir -p $(PROJECT_DIR)/sim/logs $(PROJECT_DIR)/sim/out
	$(eval _SIM_LOG := $(PROJECT_DIR)/sim/logs/sim_$(shell date +%Y%m%d_%H%M%S).log)
	@echo "Running simulation... Log: $(_SIM_LOG)"
	@tclsh $(AUTOMATION)/tcl/sim.tcl \
	    $(PROJECT_DIR) $(PROJECT_NAME) $(TOP_TB) > $(_SIM_LOG) 2>&1 || \
	    (echo "--- last 40 lines of $(_SIM_LOG) ---"; \
	     tail -40 $(_SIM_LOG); exit 1)
	@echo "Simulation complete. Log: $(_SIM_LOG)"

# ── All (synthesis then place-and-route, fully headless) ──────────────────────
all: syn par

# ── GUI targets (interactive use only — NEVER call from CI or make all) ───────
#
# WARNING: GUI targets do NOT write sentinel files (syn/out/.syn_done, etc.).
# Sources added interactively in the GUI are NOT persisted —
# the next headless make run re-syncs from .f files and removes any GUI changes.
# GUI targets must never appear as prerequisites of any other target.

syn-gui: check-env $(PROJECT_LDF)
	@echo "WARNING: GUI mode — for interactive use only. Do not invoke from CI."
	@echo "         Sources will be re-synced from src/sources.f before opening."
	@echo "         Any files added in the GUI will be removed on the next make run."
	@$(DIAMONDC) $(AUTOMATION)/tcl/sync_sources.tcl \
	    $(PROJECT_DIR) $(PROJECT_NAME)
	@$(DIAMOND_GUI) $(PROJECT_LDF) &

par-gui: check-env $(PROJECT_LDF)
	@echo "WARNING: GUI mode — for interactive use only. Do not invoke from CI."
	@echo "         Requires prior synthesis output in syn/out/."
	@if [ ! -f "$(PROJECT_DIR)/syn/out/.syn_done" ]; then \
	    echo "ERROR: No synthesis output found. Run 'make syn' first." >&2; exit 1; \
	fi
	@$(DIAMONDC) $(AUTOMATION)/tcl/sync_sources.tcl \
	    $(PROJECT_DIR) $(PROJECT_NAME)
	@$(DIAMOND_GUI) $(PROJECT_LDF) &

sim-gui: check-env $(PROJECT_LDF)
	@echo "WARNING: GUI mode — for interactive use only. Do not invoke from CI."
	@echo "         Compiling sources before opening Questa Sim GUI..."
	@mkdir -p $(PROJECT_DIR)/sim/out $(PROJECT_DIR)/sim/logs
	@$(QUESTA_BIN)/vlog \
	    -work $(PROJECT_DIR)/sim/out/work \
	    -f $(PROJECT_DIR)/src/sources.f \
	    -f $(PROJECT_DIR)/tb/tb_files.f \
	    2>&1 | tee $(PROJECT_DIR)/sim/logs/sim_gui_compile.log
	@echo "Compilation complete. Opening Questa Sim GUI..."
	@$(QUESTA_BIN)/vsim \
	    -work $(PROJECT_DIR)/sim/out/work \
	    $(TOP_TB) &

# ── IP core regeneration (explicit only — never a dependency of syn) ──────────
regen_ip: check-env $(PROJECT_LDF)
	@echo "Regenerating IP cores for $(PROJECT_NAME)..."
	@$(DIAMONDC) $(AUTOMATION)/tcl/regen_ip.tcl \
	    $(PROJECT_DIR) $(PROJECT_NAME)

# ── Clean targets ─────────────────────────────────────────────────────────────
clean:
	@echo "Cleaning all artifacts for $(PROJECT_NAME)"
	rm -rf $(PROJECT_DIR)/syn/out  $(PROJECT_DIR)/syn/logs
	rm -rf $(PROJECT_DIR)/par/out  $(PROJECT_DIR)/par/logs
	rm -rf $(PROJECT_DIR)/sim/out  $(PROJECT_DIR)/sim/logs
	rm -rf $(PRJ_DIR)

clean-syn:
	rm -rf $(PROJECT_DIR)/syn/out $(PROJECT_DIR)/syn/logs

clean-par:
	rm -rf $(PROJECT_DIR)/par/out $(PROJECT_DIR)/par/logs

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "Project: $(PROJECT_NAME)  [$(shell grep '^DEVICE=' $(META) | cut -d= -f2)-$(shell grep '^PACKAGE=' $(META) | cut -d= -f2) speed $(shell grep '^SPEED=' $(META) | cut -d= -f2)]"
	@echo "========================================================="
	@echo ""
	@echo "Environment (run once per shell session, from repo root):"
	@echo "  source _automation/env.sh    Initialize Diamond + Questa Sim environment"
	@echo ""
	@echo "Build:"
	@echo "  make create-project          Create the Diamond project in prj/ (run once)"
	@echo "  make all                     Run synthesis then place-and-route"
	@echo "  make syn                     Synthesize RTL — headless (reads src/sources.f)"
	@echo "  make par                     Place, route, generate bitstream — headless"
	@echo ""
	@echo "Simulation:"
	@echo "  make sim                     Compile and run testbench — headless (Questa Sim)"
	@echo ""
	@echo "Interactive GUI (not for CI):"
	@echo "  make syn-gui                 Sync sources, open Diamond GUI for synthesis"
	@echo "  make par-gui                 Sync sources, open Diamond GUI for place-and-route"
	@echo "  make sim-gui                 Compile sources, open Questa Sim GUI with design loaded"
	@echo ""
	@echo "IP Cores:"
	@echo "  make regen_ip                Regenerate Diamond IP cores (explicit only)"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                   Remove all artifacts and the .ldf project file"
	@echo "  make clean-syn               Remove synthesis artifacts only"
	@echo "  make clean-par               Remove place-and-route artifacts only"
	@echo ""
	@echo "Help:"
	@echo "  make help                    Show this message"
	@echo ""
	@echo "Source files:  src/sources.f       Constraint files: syn/constraints.f"
	@echo "Testbench:     tb/tb_files.f       Device config:    project.meta"
	@echo "Build output:  syn/out/ par/out/ sim/out/    Logs: syn/logs/ par/logs/ sim/logs/"
	@echo ""
