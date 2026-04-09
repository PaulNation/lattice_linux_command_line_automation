# _automation/tcl/syn_gui.tcl
# Thin wrapper: synchronizes sources from .f files then hands off to Diamond GUI.
# The user drives synthesis interactively in the GUI.
#
# Usage (standalone via diamondc):
#   diamondc syn_gui.tcl <project_dir> <project_name>
#
# NOTE: This script is for interactive use only.
#       Do NOT invoke from CI or from any automated Make target.
#       Sources added interactively in the GUI are NOT persisted —
#       the next headless make run re-syncs from .f files and removes them.

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]
source [file join $script_dir lib/file_list.tcl]
source [file join $script_dir lib/project_utils.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 2} {
    puts stderr "ERROR: syn_gui.tcl requires 2 arguments: project_dir project_name"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]

puts ""
puts "WARNING: GUI mode — for interactive use only. Do not invoke from CI."
puts "         Sources will be re-synced from src/sources.f before opening."
puts "         Any files added in the GUI will be removed on the next make run."
puts ""

# ── Resolve Diamond GUI binary ────────────────────────────────────────────────
if {![info exists env(DIAMOND_GUI)] || $env(DIAMOND_GUI) eq ""} {
    puts stderr "ERROR: DIAMOND_GUI is not set. Source _automation/env.sh first."
    exit 1
}
set diamond_gui $env(DIAMOND_GUI)

if {![file executable $diamond_gui]} {
    puts stderr "ERROR: Diamond GUI binary not found or not executable: $diamond_gui"
    exit 1
}

# ── Open project and sync sources ─────────────────────────────────────────────
open_project $project_dir $project_name

info_msg "Syncing sources from .f files before opening GUI..."
sync_rtl_sources $project_dir

close_project_clean
info_msg "Source sync complete."

# ── Launch Diamond GUI ────────────────────────────────────────────────────────
set ldf [file join $project_dir prj "${project_name}.ldf"]
info_msg "Launching Diamond GUI: $diamond_gui $ldf"

# Launch in background — Make returns immediately after this script exits.
# The GUI process is independent; closing it does not affect the build system.
if {[catch {exec $diamond_gui $ldf &} err]} {
    puts stderr "ERROR: Failed to launch Diamond GUI: $err"
    exit 1
}

info_msg "Diamond GUI launched. This script is exiting."
info_msg "Close the GUI manually when done. Do not save source changes inside the GUI."
exit 0
