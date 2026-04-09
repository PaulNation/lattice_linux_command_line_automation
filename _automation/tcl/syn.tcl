# _automation/tcl/syn.tcl
# Runs synthesis for a Diamond project.
# Syncs sources from .f files, then runs synthesis only.
# Does NOT run map, PAR, or bitstream generation — those are par.tcl's job.
#
# Usage (from Make):
#   diamondc syn.tcl <project_dir> <project_name>

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]
source [file join $script_dir lib/file_list.tcl]
source [file join $script_dir lib/project_utils.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 2} {
    puts stderr "ERROR: syn.tcl requires 2 arguments: project_dir project_name"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]

# ── Verify sources.f exists and is non-empty before doing anything ────────────
# parse_file_list will abort with a clear error if the file is missing or empty.
set sources_f [file join $project_dir src sources.f]
if {![file exists $sources_f]} {
    puts stderr "ERROR: src/sources.f not found in $project_dir"
    puts stderr "       Create the file and list at least one RTL source."
    exit 1
}

# ── Open project ──────────────────────────────────────────────────────────────
open_project $project_dir $project_name

# ── Sync sources ──────────────────────────────────────────────────────────────
info_msg "Syncing sources from .f files for synthesis..."
sync_rtl_sources $project_dir

# Save after source sync
if {[catch {prj_project save} err]} {
    puts stderr "ERROR: Failed to save project after source sync: $err"
    exit 1
}

# ── Run synthesis ─────────────────────────────────────────────────────────────
info_msg "Starting synthesis for implementation: impl1"

if {[catch {prj_run Synthesis -impl impl1} err]} {
    puts stderr "ERROR: Synthesis failed: $err"
    exit 1
}

# ── Check log for silent failures ─────────────────────────────────────────────
# Diamond can return TCL_OK even when synthesis has errors.
set syn_log_candidates [glob -nocomplain \
    [file join $project_dir syn out                  *.log] \
    [file join $project_dir prj impl1                *.log] \
    [file join $project_dir prj "${project_name}_impl1" *.log]]

foreach logfile $syn_log_candidates {
    check_log_for_errors $logfile
}

# ── Save and close ────────────────────────────────────────────────────────────
close_project_clean

info_msg "Synthesis complete."
exit 0
