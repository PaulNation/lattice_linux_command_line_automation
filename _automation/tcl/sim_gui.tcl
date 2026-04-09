# _automation/tcl/sim_gui.tcl
# Compiles RTL and testbench sources headlessly, then opens the Questa Sim GUI
# with the compiled design loaded for interactive waveform analysis.
# Invoked via tclsh (not diamondc) — does not use Diamond Tcl APIs.
#
# Usage (standalone via tclsh):
#   tclsh sim_gui.tcl <project_dir> <project_name> <top_tb>
#
# Key difference from sim.tcl:
#   vsim is invoked WITHOUT -c and WITHOUT "run -all; quit -f"
#   This opens the Questa Sim GUI with control given to the user.
#
# NOTE: For interactive use only. Do NOT invoke from CI or make all.
#       This script does NOT write sentinel files.

set script_dir [file dirname [info script]]
source [file join $script_dir lib/file_list.tcl]
source [file join $script_dir lib/error_handling.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 3} {
    puts stderr "ERROR: sim_gui.tcl requires 3 arguments: project_dir project_name top_tb"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]
set top_tb       [lindex $argv 2]

puts ""
puts "WARNING: GUI mode — for interactive use only. Do not invoke from CI."
puts "         Compiling sources headlessly before opening Questa Sim GUI..."
puts ""

if {![file isdirectory $project_dir]} {
    puts stderr "ERROR: Project directory does not exist: $project_dir"
    exit 1
}

# ── Get Questa binary paths from environment ──────────────────────────────────
if {![info exists env(QUESTA_BIN)] || $env(QUESTA_BIN) eq ""} {
    puts stderr "ERROR: QUESTA_BIN is not set. Source _automation/env.sh first."
    exit 1
}

set questa_bin $env(QUESTA_BIN)
set vlog_bin   [file join $questa_bin vlog]
set vcom_bin   [file join $questa_bin vcom]
set vsim_bin   [file join $questa_bin vsim]

foreach bin [list $vlog_bin $vsim_bin] {
    if {![file executable $bin]} {
        puts stderr "ERROR: Questa binary not found or not executable: $bin"
        puts stderr "       Check QUESTA_BIN in _automation/paths.cfg"
        exit 1
    }
}

# ── Work library path ─────────────────────────────────────────────────────────
set work_lib [file join $project_dir sim out work]
file mkdir [file join $project_dir sim out]

# ── Helpers (duplicated from sim.tcl to keep scripts self-contained) ──────────
proc split_by_language {filelist sv_var vhdl_var} {
    upvar $sv_var sv_files
    upvar $vhdl_var vhdl_files
    set sv_files   {}
    set vhdl_files {}
    foreach f $filelist {
        set ext [string tolower [file extension $f]]
        if {$ext eq ".v" || $ext eq ".sv"} {
            lappend sv_files $f
        } elseif {$ext eq ".vhd" || $ext eq ".vhdl"} {
            lappend vhdl_files $f
        } else {
            puts stderr "ERROR: Unrecognized file extension for simulation: $f"
            exit 1
        }
    }
}

proc compile_files {compiler work_lib files stage} {
    if {[llength $files] == 0} { return }
    set cmd [concat [list $compiler -work $work_lib] $files]
    if {[catch {exec {*}$cmd} output]} {
        puts stderr "ERROR: $compiler failed during $stage"
        puts stderr $output
        exit 1
    }
    puts $output
    # Check for Questa error patterns in compilation output
    foreach line [split $output "\n"] {
        if {[regexp {^(\*\*\s+Error|\*\*\s+Fatal)} $line]} {
            puts stderr "ERROR: Compilation error detected: $line"
            exit 1
        }
    }
}

# ── Parse .f files ────────────────────────────────────────────────────────────
set sources_f [file join $project_dir src sources.f]
set tb_f      [file join $project_dir tb tb_files.f]

set rtl_files [parse_file_list $sources_f $project_dir]
set tb_files  [parse_file_list $tb_f $project_dir]

# ── Steps 1-2: Compile RTL and testbench (identical to sim.tcl) ───────────────
info_msg "Compiling RTL sources into: $work_lib"
split_by_language $rtl_files rtl_sv rtl_vhdl
compile_files $vlog_bin $work_lib $rtl_sv   "RTL Verilog/SystemVerilog compilation"
compile_files $vcom_bin $work_lib $rtl_vhdl "RTL VHDL compilation"

info_msg "Compiling testbench sources..."
split_by_language $tb_files tb_sv tb_vhdl
compile_files $vlog_bin $work_lib $tb_sv   "testbench Verilog/SystemVerilog compilation"
compile_files $vcom_bin $work_lib $tb_vhdl "testbench VHDL compilation"

# ── Launch Questa Sim GUI ─────────────────────────────────────────────────────
# Key: no -c flag, no -do "run -all; quit -f"
# This opens the Questa Sim GUI with the compiled design loaded.
# The & detaches the process so this script returns immediately.
info_msg "Compilation complete. Opening Questa Sim GUI..."
info_msg "  vsim -work $work_lib $top_tb"
puts ""
puts "Questa Sim GUI is opening with '$top_tb' loaded."
puts "Use the GUI to add waves, run simulation, and inspect results."
puts "This script is exiting — the Questa Sim process runs independently."
puts ""

if {[catch {exec $vsim_bin \
    -work $work_lib \
    $top_tb &} err]} {
    puts stderr "ERROR: Failed to launch Questa Sim GUI: $err"
    exit 1
}

exit 0
