# Diamond FPGA Automation Workspace

## What this repo is
A multi-project Lattice Diamond FPGA automation framework.
Full specification: _automation/SPEC.md — read it before doing anything.

## Hard rules (never violate these)
- One directory = one Diamond project
- All policy lives in _automation/ only
- Makefiles are dumb traffic controllers — no tool paths, no device info
- Tcl does all real work — always exit 1 on failure, never fall through
- Device/package/performance-grade live only in project.meta
- .f files are source truth — never hardcode file lists anywhere else
- GUI targets (syn-gui, par-gui, sim-gui) are never CI dependencies
- paths.cfg is machine-local and gitignored — paths.cfg.example is committed

## Key paths on this machine
- Diamond: /home/pnieves/lscc/diamond/3.14/bin/lin64/diamondc
- Diamond GUI: /home/pnieves/lscc/diamond/3.14/bin/lin64/diamond
- Questa: /home/pnieves/lscc/diamond/3.14/questasim/linux_x86_64/vsim
- Diamond version: 3.14

## Output layout
- syn/out/ and syn/logs/   ← synthesis artifacts
- par/out/ and par/logs/   ← P&R artifacts + bitstream
- sim/out/ and sim/logs/   ← Questa work library
