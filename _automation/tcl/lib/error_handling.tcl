# _automation/tcl/lib/error_handling.tcl
# Shared error-handling utilities for all Diamond Tcl scripts.
#
# Usage:
#   source [file join [file dirname [info script]] lib/error_handling.tcl]

# run_or_die -- Execute a Diamond API command inside catch.
# On error, prints the message with context to stderr and exits 1.
proc run_or_die {cmd} {
    if {[catch {uplevel 1 $cmd} err]} {
        puts stderr "ERROR: Command failed: $cmd"
        puts stderr "ERROR: $err"
        exit 1
    }
}

# check_log_for_errors -- Scan a log file for ERROR: or FATAL: lines.
# Diamond can return TCL_OK even after a failed run — always check the log.
# If any ERROR: or FATAL: lines are found, prints the first match and exits 1.
proc check_log_for_errors {logfile} {
    if {![file exists $logfile]} {
        puts stderr "ERROR: Expected log file not found: $logfile"
        exit 1
    }
    set fh [open $logfile r]
    set content [read $fh]
    close $fh
    if {[regexp -nocase -line {^\s*(ERROR|FATAL):} $content]} {
        puts stderr "ERROR: Errors found in log: $logfile"
        # Print the first ERROR/FATAL line for quick CI diagnosis
        foreach line [split $content "\n"] {
            if {[regexp -nocase {^\s*(ERROR|FATAL):} $line]} {
                puts stderr "  $line"
                break
            }
        }
        exit 1
    }
}

# die -- Print a message to stderr and exit 1.
# Always use this instead of bare "exit 1" so the error is clearly labeled.
proc die {msg} {
    puts stderr "ERROR: $msg"
    exit 1
}

# info_msg -- Print an informational message with a consistent prefix.
proc info_msg {msg} {
    puts "INFO: $msg"
}
