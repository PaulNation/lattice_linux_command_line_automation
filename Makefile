DEVICE     ?= DEVICE_TBD
PACKAGE    ?= PACKAGE_TBD
PERF_GRADE ?= 0

.PHONY: init list help

init:
ifndef PROJECT
	$(error PROJECT is required. Usage: make init PROJECT=MyProjectName)
endif
	@bash _automation/scaffold.sh "$(PROJECT)" "$(DEVICE)" "$(PACKAGE)" "$(PERF_GRADE)"

list:
	@echo ""
	@echo "Projects in this repository:"
	@echo "-----------------------------"
	@found=0; \
	for d in */; do \
	    if [ -f "$$d/project.meta" ]; then \
	        dev=$$(grep '^DEVICE='     "$$d/project.meta" | cut -d= -f2); \
	        pkg=$$(grep '^PACKAGE='    "$$d/project.meta" | cut -d= -f2); \
	        spd=$$(grep '^PERF_GRADE=' "$$d/project.meta" | cut -d= -f2); \
	        printf "  %-24s %s-%s (performance grade %s)\n" "$${d%/}" "$$dev" "$$pkg" "$$spd"; \
	        found=1; \
	    fi; \
	done; \
	[ "$$found" -eq 0 ] && echo "  (none — run: make init PROJECT=<name>)"
	@echo ""

help:
	@echo ""
	@echo "Diamond FPGA Workspace — Root Commands"
	@echo "======================================================="
	@echo ""
	@echo "  make init PROJECT=<n>            Scaffold a new project with all boilerplate"
	@echo "  make init PROJECT=<n> \\"
	@echo "       DEVICE=<d> PACKAGE=<p> \\"
	@echo "       PERF_GRADE=<g>           Scaffold and pre-fill device info"
	@echo "  make list                        List all projects and their target devices"
	@echo "  make help                        Show this message"
	@echo ""
	@echo "After init, cd into the project and run: make help"
