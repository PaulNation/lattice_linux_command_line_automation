# _automation/tcl/lib/file_list.tcl
# Parser for .f file lists (sources.f, constraints.f, tb_files.f).
#
# .f file format rules (per SPEC.md):
#   - Paths are relative to the project root (directory containing project.meta)
#   - Lines beginning with # are comments and are ignored
#   - Blank lines are ignored
#   - Paths must not use wildcards (* ? **)
#   - Mixed VHDL and Verilog are permitted (language inferred from extension)
#   - constraints.f lists only .lpf and .ldc files — no RTL
#   - tb_files.f lists only testbench files — never shared RTL from sources.f
#
# Usage:
#   source [file join [file dirname [info script]] lib/file_list.tcl]
#   set files [parse_file_list /path/to/sources.f /path/to/project_root]

# parse_file_list -- Parse a .f file and return a list of absolute paths.
# Each path is resolved relative to project_root.
# Aborts with exit 1 if:
#   - The .f file does not exist
#   - The .f file is empty or has no valid entries
#   - Any listed file is missing on disk
#   - A wildcard is detected in any path
proc parse_file_list {flist_path project_root} {
    if {![file exists $flist_path]} {
        puts stderr "ERROR: File list not found: $flist_path"
        exit 1
    }

    set fh [open $flist_path r]
    set lines [split [read $fh] "\n"]
    close $fh

    set result {}
    set lineno 0
    foreach line $lines {
        incr lineno
        set line [string trim $line]
        # Skip comments and blank lines
        if {$line eq "" || [string index $line 0] eq "#"} {
            continue
        }
        # Reject wildcards — .f files must list files explicitly
        if {[regexp {[*?]} $line]} {
            puts stderr "ERROR: Wildcard detected in $flist_path line $lineno: $line"
            puts stderr "       .f files must list files explicitly — no globs."
            exit 1
        }
        # Resolve relative to project root
        set abs_path [file join $project_root $line]
        if {![file exists $abs_path]} {
            puts stderr "ERROR: File listed in $flist_path does not exist on disk:"
            puts stderr "       $abs_path"
            puts stderr "       (line $lineno: $line)"
            exit 1
        }
        lappend result $abs_path
    }

    if {[llength $result] == 0} {
        puts stderr "ERROR: File list is empty or contains no valid entries: $flist_path"
        puts stderr "       At least one source file is required."
        exit 1
    }

    return $result
}

# infer_language -- Return the Diamond language type string for a file extension.
# Returns: "verilog", "vhdl", "lpf", "ldc", or "" if unknown.
proc infer_language {filepath} {
    set ext [string tolower [file extension $filepath]]
    switch -- $ext {
        ".v"    { return "verilog" }
        ".sv"   { return "verilog" }
        ".vhd"  { return "vhdl" }
        ".vhdl" { return "vhdl" }
        ".lpf"  { return "lpf" }
        ".ldc"  { return "ldc" }
        default { return "" }
    }
}
