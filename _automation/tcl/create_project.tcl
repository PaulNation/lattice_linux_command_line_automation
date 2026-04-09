# _automation/tcl/create_project.tcl
# Creates a new Lattice Diamond project (.ldf) from project.meta data.
# Idempotent: exits cleanly if the .ldf already exists.
#
# Usage (from Make via common.mk):
#   diamondc create_project.tcl <project_dir> <project_name> <device> <package> <speed>

set script_dir [file dirname [info script]]
source [file join $script_dir lib/error_handling.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 5} {
    puts stderr "ERROR: create_project.tcl requires 5 arguments:"
    puts stderr "       project_dir project_name device package speed"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]
set device       [lindex $argv 2]
set package      [lindex $argv 3]
set speed        [lindex $argv 4]

# ── Validate arguments ────────────────────────────────────────────────────────
if {![file isdirectory $project_dir]} {
    puts stderr "ERROR: project_dir does not exist: $project_dir"
    exit 1
}

if {$device eq "" || $device eq "DEVICE_TBD"} {
    puts stderr "ERROR: DEVICE is not set. Fill in project.meta before running."
    exit 1
}

# ── Idempotency check ─────────────────────────────────────────────────────────
set ldf [file join $project_dir "${project_name}.ldf"]
if {[file exists $ldf]} {
    puts "INFO: Project already exists, skipping creation: $ldf"
    exit 0
}

# ── Change to project directory ───────────────────────────────────────────────
# prj_project new has no -path flag; the project is created in the CWD.
if {[catch {cd $project_dir} err]} {
    puts stderr "ERROR: Cannot cd to project_dir '$project_dir': $err"
    exit 1
}

# ── Create new Diamond project ────────────────────────────────────────────────
info_msg "Creating Diamond project: $project_name"
info_msg "  Device:  $device"
info_msg "  LDF:     $ldf"

if {[catch {
    prj_project new \
        -name $project_name \
        -impl "impl1"       \
        -dev  $device
} err]} {
    puts stderr "ERROR: prj_project new failed: $err"
    exit 1
}

# ── Save and close ────────────────────────────────────────────────────────────
# NOTE: prj/<project_name>.lpf was created and registered by prj_project new.
# Leave it exactly as Diamond created it — it is the canonical constraint file.
# The user edits prj/<project_name>.lpf directly for pin assignments.
# Automation scripts must never add, remove, or replace it.
if {[catch {prj_project save} err]} {
    puts stderr "ERROR: Failed to save project after creation: $err"
    exit 1
}

if {[catch {prj_project close} err]} {
    puts stderr "ERROR: Failed to close project after creation: $err"
    exit 1
}

info_msg "Project created successfully: $ldf"
exit 0
