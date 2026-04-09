# _automation/tcl/par.tcl
# Runs map, place-and-route, and bitstream generation for a Diamond project.
# Reads synthesis output from syn/out/, writes bitstream to par/out/.
# Calls check_timing.tcl as a subroutine after PAR completes.
#
# Usage (from Make):
#   diamondc par.tcl <project_dir> <project_name>

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]
source [file join $script_dir lib/file_list.tcl]
source [file join $script_dir lib/project_utils.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 2} {
    puts stderr "ERROR: par.tcl requires 2 arguments: project_dir project_name"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]

# ── Open project ──────────────────────────────────────────────────────────────
open_project $project_dir $project_name

# ── Sync sources and constraints ──────────────────────────────────────────────
info_msg "Syncing sources from .f files for place-and-route..."
sync_rtl_sources $project_dir

if {[catch {prj_project save} err]} {
    puts stderr "ERROR: Failed to save project after source sync: $err"
    exit 1
}

# ── Run Map ───────────────────────────────────────────────────────────────────
info_msg "Running Map..."
if {[catch {prj_run Map -impl impl1} err]} {
    puts stderr "ERROR: Map failed: $err"
    exit 1
}

set map_logs [glob -nocomplain \
    [file join $project_dir prj "${project_name}_impl1" *.log] \
    [file join $project_dir prj impl1                   *.log]]
foreach logfile $map_logs {
    check_log_for_errors $logfile
}

# ── Run Place-and-Route ───────────────────────────────────────────────────────
info_msg "Running Place-and-Route..."
if {[catch {prj_run PAR -impl impl1} err]} {
    puts stderr "ERROR: Place-and-route failed: $err"
    exit 1
}

set par_logs [glob -nocomplain \
    [file join $project_dir prj "${project_name}_impl1" *.log] \
    [file join $project_dir prj impl1                   *.log]]
foreach logfile $par_logs {
    check_log_for_errors $logfile
}

# ── Export bitstream ──────────────────────────────────────────────────────────
info_msg "Exporting bitstream to par/out/..."
set par_out [file join $project_dir par out]
file mkdir $par_out

if {[catch {prj_run Export -impl impl1 -task Bitgen} err]} {
    puts stderr "ERROR: Bitstream export failed: $err"
    exit 1
}

# ── Save and close ────────────────────────────────────────────────────────────
close_project_clean

# ── Check timing (mandatory post-PAR step) ────────────────────────────────────
# Source check_timing.tcl as a subroutine — project_dir and project_name are
# already set in this scope and will be visible to the sourced script.
info_msg "Running post-PAR timing verification..."
if {[catch {source [file join $script_dir check_timing.tcl]} err]} {
    # check_timing.tcl calls exit 1 directly on violations.
    # If we reach here, a Tcl error (not a timing failure) occurred.
    puts stderr "ERROR: Timing check script encountered an error: $err"
    exit 1
}

info_msg "Place-and-route complete."
exit 0
