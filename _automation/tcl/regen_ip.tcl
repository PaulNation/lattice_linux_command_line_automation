# _automation/tcl/regen_ip.tcl
# Regenerates Diamond IP cores listed in src/ip/ for a project.
# Must be invoked explicitly — never a dependency of syn.
#
# Usage (from Make):
#   diamondc regen_ip.tcl <project_dir> <project_name>
#
# Rules:
#   - Validates Diamond version against DIAMOND_MIN_VERSION from project.meta
#   - Scans src/ip/ for IP definition files (.sbx / .ipx)
#   - If no IP cores found, emits a benign message and exits 0
#   - Regenerates each found IP core using prj_run IPRegenerate
#   - Exits 1 on any error

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]
source [file join $script_dir lib/project_utils.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 2} {
    puts stderr "ERROR: regen_ip.tcl requires 2 arguments: project_dir project_name"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]

if {![file isdirectory $project_dir]} {
    puts stderr "ERROR: Project directory does not exist: $project_dir"
    exit 1
}

# ── Read minimum Diamond version from project.meta ────────────────────────────
set min_ver [read_meta $project_dir "DIAMOND_MIN_VERSION" "3.14"]
info_msg "DIAMOND_MIN_VERSION from project.meta: $min_ver"

# ── Check actual Diamond version ──────────────────────────────────────────────
# dia_version returns the running Diamond version string.
# prj_version is not a standard command; use the running interpreter's version.
if {[catch {set actual_ver [dia_version]} err]} {
    # Fall back: try to get version from the $prog_dir or diamondc info
    set actual_ver ""
}

if {$actual_ver ne ""} {
    # Compare version numbers
    if {![catch {
        lassign [split $actual_ver "."] maj_a min_a
        lassign [split $min_ver    "."] maj_r min_r
        set ok [expr {
            ($maj_a > $maj_r) ||
            ($maj_a == $maj_r && $min_a >= $min_r)
        }]
    } cmp_err]} {
        if {!$ok} {
            puts stderr "ERROR: Diamond version mismatch for IP regeneration."
            puts stderr "       Required: $min_ver  Found: $actual_ver"
            puts stderr "       IP regeneration requires an exact or newer Diamond version."
            puts stderr "       Use the committed generated IP files for this Diamond version."
            exit 1
        }
        info_msg "Diamond version check passed: $actual_ver >= $min_ver"
    }
} else {
    puts "WARNING: Could not determine Diamond version. Proceeding with IP regeneration."
    puts "         Ensure Diamond $min_ver or newer is installed."
}

# ── Locate IP core definition files ──────────────────────────────────────────
set ip_dir [file join $project_dir src ip]

if {![file isdirectory $ip_dir]} {
    info_msg "No src/ip/ directory found for project: $project_name"
    info_msg "No IP cores to regenerate. Exiting cleanly."
    exit 0
}

# Collect .sbx and .ipx files recursively under src/ip/
set ip_files {}
foreach ext {*.sbx *.ipx} {
    set found [glob -nocomplain -directory $ip_dir -type f $ext]
    set ip_files [concat $ip_files $found]
}

# Also search subdirectories
foreach subdir [glob -nocomplain -directory $ip_dir -type d *] {
    foreach ext {*.sbx *.ipx} {
        set found [glob -nocomplain -directory $subdir -type f $ext]
        set ip_files [concat $ip_files $found]
    }
}

if {[llength $ip_files] == 0} {
    info_msg "No IP core definition files (.sbx/.ipx) found in src/ip/."
    info_msg "No IP cores to regenerate for project: $project_name"
    exit 0
}

info_msg "Found [llength $ip_files] IP core(s) to regenerate:"
foreach f $ip_files {
    info_msg "  $f"
}

# ── Open project ──────────────────────────────────────────────────────────────
open_project $project_dir $project_name

# ── Regenerate each IP core ───────────────────────────────────────────────────
set failed 0
foreach ip_file $ip_files {
    set core_name [file rootname [file tail $ip_file]]
    info_msg "Regenerating IP core: $core_name ($ip_file)"

    if {[catch {prj_run IPRegenerate -impl impl1 -ipfile $ip_file} err]} {
        puts stderr "ERROR: IP regeneration failed for: $core_name"
        puts stderr "       $err"
        set failed 1
    } else {
        info_msg "  $core_name regenerated successfully."
    }
}

# ── Save and close ────────────────────────────────────────────────────────────
close_project_clean

if {$failed} {
    puts stderr "ERROR: One or more IP cores failed to regenerate. See above."
    exit 1
}

info_msg "IP regeneration complete for project: $project_name"
puts ""
puts "IMPORTANT: Verify regenerated output files, update sources.f if new files"
puts "           were generated, and commit all changes to version control."
puts "           Generated IP outputs (src/ip/**) are committed per policy."
exit 0
