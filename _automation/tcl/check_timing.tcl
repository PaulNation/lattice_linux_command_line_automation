# _automation/tcl/check_timing.tcl
# Post-PAR timing verification script.
# Parses the Diamond timing report (.twr) in par/out/ for negative slack paths.
# Prints a formatted table of violations, exits 1 if any path exceeds threshold.
#
# Usage (standalone):
#   diamondc check_timing.tcl <project_dir> <project_name>
#
# Usage (sourced from par.tcl):
#   source check_timing.tcl
#   (project_dir and project_name must be set in the calling scope)

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]
source [file join $script_dir lib/project_utils.tcl]

# ── Resolve project_dir / project_name ───────────────────────────────────────
# Supports both: sourced from par.tcl (vars already set) or run standalone.
if {![info exists project_dir] || ![info exists project_name]} {
    if {$argc < 2} {
        puts stderr "ERROR: check_timing.tcl requires 2 arguments: project_dir project_name"
        exit 1
    }
    set project_dir  [lindex $argv 0]
    set project_name [lindex $argv 1]
}

# ── Read timing slack threshold from project.meta ─────────────────────────────
# TIMING_SLACK_THRESHOLD defaults to 0 (any negative slack fails the build).
set threshold [read_meta $project_dir "TIMING_SLACK_THRESHOLD" "0"]
# Convert to a number; guard against non-numeric values.
if {[catch {expr {$threshold + 0.0}} thresh_val]} {
    puts stderr "ERROR: Invalid TIMING_SLACK_THRESHOLD in project.meta: '$threshold'"
    exit 1
}

info_msg "Timing check: project=$project_name  threshold=${threshold}ns"

# ── Locate timing report ──────────────────────────────────────────────────────
# Diamond generates .twr (timing with results) and/or .par (PAR report).
# Check par/out/ first, then implementation directories.
set par_out [file join $project_dir par out]
set twr_candidates [glob -nocomplain \
    [file join $par_out          *.twr] \
    [file join $project_dir "${project_name}_impl1" *.twr] \
    [file join $project_dir impl1 *.twr]]

# Also look in par/out for par reports
set par_candidates [glob -nocomplain \
    [file join $par_out          *.par] \
    [file join $project_dir "${project_name}_impl1" *.par]]

set report_files [concat $twr_candidates $par_candidates]

if {[llength $report_files] == 0} {
    puts stderr "WARNING: No timing report (.twr/.par) found in par/out/ or impl directory."
    puts stderr "         Timing check skipped. Ensure PAR completed successfully."
    # Do not fail here — timing report absence may mean timing was not requested.
    exit 0
}

# Use the most recently modified report
set report_file [lindex [lsort -command {apply {{a b} {
    expr {[file mtime $b] - [file mtime $a]}
}}} $report_files] 0]

info_msg "Parsing timing report: $report_file"

# ── Parse the timing report for negative slack ────────────────────────────────
set fh [open $report_file r]
set content [read $fh]
close $fh

# Diamond .twr format examples:
#   Slack: -1.234ns (setup)
#   Slack:  1.234ns
#   Timing constraint: sys_clk period ...
#     Slack: -0.567ns

set failing_paths {}
set current_constraint ""

foreach line [split $content "\n"] {
    # Track which timing constraint we're in
    if {[regexp {Timing constraint:\s+(.+)} $line -> constraint_name]} {
        set current_constraint [string trim $constraint_name]
    }

    # Match slack lines — handle both positive and negative
    if {[regexp {Slack:\s*([+-]?\d+\.?\d*)\s*ns} $line -> slack_str]} {
        set slack_val [expr {double($slack_str)}]
        if {$slack_val < 0} {
            lappend failing_paths [list $current_constraint $slack_val]
        }
    }
}

# ── Report results ────────────────────────────────────────────────────────────
if {[llength $failing_paths] == 0} {
    info_msg "Timing PASSED — no negative slack paths detected."
    exit 0
}

# Print formatted table of failing paths
puts ""
puts "┌──────────────────────────────────────────────┬───────────────┐"
puts "│ Constraint                                   │ Slack (ns)    │"
puts "├──────────────────────────────────────────────┼───────────────┤"
foreach entry $failing_paths {
    set constraint [lindex $entry 0]
    set slack      [lindex $entry 1]
    set constraint_trunc [string range $constraint 0 44]
    puts [format "│ %-44s │ %+13.3f │" $constraint_trunc $slack]
}
puts "└──────────────────────────────────────────────┴───────────────┘"
puts ""

# ── Check against threshold ───────────────────────────────────────────────────
set worst_slack 0.0
foreach entry $failing_paths {
    set slack [lindex $entry 1]
    if {$slack < $worst_slack} {
        set worst_slack $slack
    }
}

if {$worst_slack < $thresh_val} {
    puts stderr "ERROR: Timing FAILED — worst slack ${worst_slack}ns exceeds threshold ${threshold}ns"
    puts stderr "       [llength $failing_paths] path(s) with negative slack."
    puts stderr "       Fix timing violations or set TIMING_SLACK_THRESHOLD in project.meta"
    puts stderr "       (default is 0 — any negative slack fails the build)."
    exit 1
} else {
    puts "WARNING: [llength $failing_paths] path(s) with negative slack,"
    puts "         but worst (${worst_slack}ns) is within threshold (${threshold}ns)."
    puts "         Build continues. Fix violations before tape-out."
    exit 0
}
