# _automation/tcl/sim.tcl
# Runs headless Questa Sim functional simulation for a project.
# Invoked via tclsh (not diamondc) — does not use Diamond Tcl APIs.
#
# Usage (from Make):
#   tclsh sim.tcl <project_dir> <project_name> <top_tb>
#
# Steps:
#   1. Compile RTL sources (vlog/vcom) into sim/out/work
#   2. Compile testbench sources separately into the same work library
#   3. Launch vsim -c headlessly: "run -all; quit -f"
#   4. Scan output for Questa error/fatal prefixes — exit 1 if found
#   5. Never invoke the Questa GUI (vsim without -c is forbidden here)

set script_dir [file dirname [info script]]
source [file join $script_dir lib/file_list.tcl]
source [file join $script_dir lib/error_handling.tcl]

# ── Parse arguments ───────────────────────────────────────────────────────────
if {$argc < 3} {
    puts stderr "ERROR: sim.tcl requires 3 arguments: project_dir project_name top_tb"
    exit 1
}

set project_dir  [lindex $argv 0]
set project_name [lindex $argv 1]
set top_tb       [lindex $argv 2]

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

# ── Helper: check questa output for silent failures ───────────────────────────
# Questa returns exit 0 even on assertion failures unless $fatal is used.
# Spec error patterns: "# Error:", "** Error", "# Fatal:"
proc check_questa_output {output stage} {
    set error_patterns {
        {^\s*#\s+Error:}
        {^\*\*\s+Error}
        {^\s*#\s+Fatal:}
        {^\*\*\s+Fatal}
    }
    set found 0
    foreach line [split $output "\n"] {
        foreach pat $error_patterns {
            if {[regexp $pat $line]} {
                if {!$found} {
                    puts stderr "ERROR: Questa Sim reported errors during $stage:"
                }
                puts stderr "  $line"
                set found 1
                break
            }
        }
    }
    if {$found} { exit 1 }
}

# ── Helper: split files by language ──────────────────────────────────────────
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

# ── Helper: compile a batch of files ─────────────────────────────────────────
proc compile_files {compiler work_lib files stage} {
    if {[llength $files] == 0} { return }
    set cmd [concat [list $compiler -work $work_lib] $files]
    if {[catch {exec {*}$cmd} output]} {
        puts stderr "ERROR: $compiler failed during $stage"
        puts stderr $output
        exit 1
    }
    puts $output
    check_questa_output $output $stage
}

# ── Step 1: Parse .f files ────────────────────────────────────────────────────
set sources_f [file join $project_dir src sources.f]
set tb_f      [file join $project_dir tb tb_files.f]

set rtl_files [parse_file_list $sources_f $project_dir]
set tb_files  [parse_file_list $tb_f $project_dir]

# ── Step 2: Compile RTL sources ───────────────────────────────────────────────
info_msg "Compiling RTL sources into: $work_lib"
split_by_language $rtl_files rtl_sv rtl_vhdl
compile_files $vlog_bin $work_lib $rtl_sv   "RTL Verilog/SystemVerilog compilation"
compile_files $vcom_bin $work_lib $rtl_vhdl "RTL VHDL compilation"

# ── Step 3: Compile testbench sources ─────────────────────────────────────────
info_msg "Compiling testbench sources..."
split_by_language $tb_files tb_sv tb_vhdl
compile_files $vlog_bin $work_lib $tb_sv   "testbench Verilog/SystemVerilog compilation"
compile_files $vcom_bin $work_lib $tb_vhdl "testbench VHDL compilation"

# ── Step 4: Run headless simulation ──────────────────────────────────────────
info_msg "Launching headless simulation: $top_tb"
info_msg "  vsim -c -do \"run -all; quit -f\" $top_tb"

set vsim_cmd [list $vsim_bin -c \
    -work $work_lib \
    -do "run -all; quit -f" \
    $top_tb]

if {[catch {exec {*}$vsim_cmd} sim_output]} {
    puts stderr "ERROR: vsim returned a non-zero exit code"
    puts stderr $sim_output
    exit 1
}

puts $sim_output

# ── Step 5: Scan for silent Questa failures ───────────────────────────────────
check_questa_output $sim_output "simulation run"

info_msg "Simulation complete: $top_tb"
exit 0
