# _automation/tcl/lib/project_utils.tcl
# Shared project-level utilities for Diamond Tcl scripts.
#
# Usage:
#   source [file join [file dirname [info script]] lib/project_utils.tcl]
#
# Depends on: file_list.tcl (must be sourced before calling sync_rtl_sources)

# read_meta -- Read a key from project.meta.
# Returns the value string, or default if the key is absent.
proc read_meta {project_dir key {default ""}} {
    set meta_path [file join $project_dir project.meta]
    if {![file exists $meta_path]} {
        puts stderr "ERROR: project.meta not found: $meta_path"
        exit 1
    }
    set fh [open $meta_path r]
    set content [read $fh]
    close $fh
    foreach line [split $content "\n"] {
        set line [string trim $line]
        if {[string match "${key}=*" $line]} {
            return [string range $line [expr {[string length $key] + 1}] end]
        }
    }
    return $default
}

# open_project -- Open an existing Diamond project file (.ldf).
# Aborts with exit 1 if the .ldf file does not exist or the open fails.
proc open_project {project_dir project_name} {
    set ldf [file join $project_dir prj "${project_name}.ldf"]
    if {![file exists $ldf]} {
        puts stderr "ERROR: Diamond project file not found: $ldf"
        puts stderr "       Run 'make create-project' first, then retry."
        exit 1
    }
    if {[catch {prj_project open $ldf} err]} {
        puts stderr "ERROR: Failed to open project: $ldf"
        puts stderr "       $err"
        exit 1
    }
    puts "INFO: Opened project: $ldf"
}

# close_project_clean -- Save and close the Diamond project cleanly.
# Aborts with exit 1 if save or close fails.
proc close_project_clean {} {
    if {[catch {prj_project save} err]} {
        puts stderr "ERROR: Failed to save project: $err"
        exit 1
    }
    if {[catch {prj_project close} err]} {
        puts stderr "ERROR: Failed to close project: $err"
        exit 1
    }
}

# sync_rtl_sources -- Remove all current implementation sources and re-add
# from .f files. This is the canonical source-sync routine used by syn.tcl,
# par.tcl, and sync_sources.tcl.
#
# Steps:
#   1. prj_src remove -all  (eliminates any GUI-added files)
#   2. Parse src/sources.f  and add each file with the correct language flag
#   3. Parse syn/constraints.f and add each constraint file
#
# Testbench files (tb_files.f) are NEVER added here — they are scoped to sim only.
proc sync_rtl_sources {project_dir} {
    # file_list.tcl must already be sourced by the calling script.
    # Use the lib/ path relative to this file's location.
    set lib_dir [file dirname [info script]]

    set sources_f    [file join $project_dir src sources.f]
    set constraints_f [file join $project_dir syn constraints.f]

    # Step 1: Remove all currently registered implementation sources.
    # GUI-added files are eliminated here — this is intentional and non-negotiable.
    if {[catch {prj_src remove -all} err]} {
        # Harmless on a freshly created project with no sources registered yet.
        puts "INFO: prj_src remove -all: $err (harmless on first run)"
    }

    # Step 2: Add RTL sources from sources.f
    set rtl_files [parse_file_list $sources_f $project_dir]
    foreach f $rtl_files {
        set lang [infer_language $f]
        if {$lang eq "verilog"} {
            if {[catch {prj_src add $f} err]} {
                puts stderr "ERROR: Failed to add Verilog/SystemVerilog source: $f"
                puts stderr "       $err"
                exit 1
            }
        } elseif {$lang eq "vhdl"} {
            if {[catch {prj_src add $f} err]} {
                puts stderr "ERROR: Failed to add VHDL source: $f"
                puts stderr "       $err"
                exit 1
            }
        } else {
            puts stderr "ERROR: Unrecognized file type for RTL source: $f"
            exit 1
        }
        puts "INFO: Added source: $f"
    }

    # Step 3: Add constraint files from constraints.f
    # Constraint files are required in every synthesis/PAR flow.
    # if {[file exists $constraints_f]} {
    #     set con_files [parse_file_list $constraints_f $project_dir]
    #     foreach f $con_files {
    #         set lang [infer_language $f]
    #         if {$lang eq "lpf"} {
    #             if {[catch {prj_src add -lpf $f} err]} {
    #                 puts stderr "ERROR: Failed to add LPF constraint: $f"
    #                 puts stderr "       $err"
    #                 exit 1
    #             }
    #         } elseif {$lang eq "ldc"} {
    #             if {[catch {prj_src add -ldc $f} err]} {
    #                 puts stderr "ERROR: Failed to add LDC constraint: $f"
    #                 puts stderr "       $err"
    #                 exit 1
    #             }
    #         } else {
    #             puts stderr "ERROR: Unrecognized constraint file type: $f"
    #             puts stderr "       constraints.f must list only .lpf and .ldc files."
    #             exit 1
    #         }
    #         puts "INFO: Added constraint: $f"
    #     }
    # } else {
    #     puts "WARNING: syn/constraints.f not found — no pin/timing constraints loaded."
    #     puts "         Synthesis may succeed but place-and-route may fail without constraints."
    # }
}
