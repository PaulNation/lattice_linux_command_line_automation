# _automation/tcl/sync_sources.tcl
# Synchronizes sources from .f files into the Diamond project.
# Does NOT run any flow stage — used by GUI targets as a standalone step.
#
# Usage (from Make GUI targets):
#   diamondc sync_sources.tcl <project_dir> <project_name>
#
# Both syn.tcl and par.tcl call sync_rtl_sources() internally as a subroutine.
# This script exists so GUI targets can sync sources without running a full flow.

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]
source [file join $script_dir lib/file_list.tcl]
source [file join $script_dir lib/project_utils.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 2} {
    puts stderr "ERROR: sync_sources.tcl requires 2 arguments: project_dir project_name"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]

# ── Open project ──────────────────────────────────────────────────────────────
open_project $project_dir $project_name

# ── Sync sources ──────────────────────────────────────────────────────────────
info_msg "Syncing sources from .f files..."
sync_rtl_sources $project_dir

# ── Save and close ────────────────────────────────────────────────────────────
close_project_clean
info_msg "Source sync complete."
exit 0
