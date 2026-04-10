# Diamond FPGA Automation Workspace (Batch Flow)

## What this repo is
A multi-project Lattice Diamond FPGA automation framework using **batch tools**.
All builds run from Make, invoking synthesis/map/par/bitgen batch tools directly.
Full specification: _automation/SPEC.md — read it before doing anything.

## Hard rules (BATCH FLOW - never violate these)
- One directory = one FPGA project (NO .ldf file created)
- All policy lives in _automation/ only
- Makefiles are dumb traffic controllers — no tool paths, no device info
- Batch tools invoked directly from Make — no Tcl project scripts
- Batch tools write outputs to their invocation directory (syn/out/, par/out/, pgrm/)
- Device/package/perf-grade/OC live only in project.meta (ARCH, DEVICE, PACKAGE, PERF_GRADE, OC fields)
- .f files are source truth — never hardcode file lists anywhere else
- par/top.lpf is user pin assignment truth — referenced directly by map -lpf flag
- Synthesis, map, par, bitgen all invoked from Make recipes with batch arguments
- paths.cfg is machine-local and gitignored — paths.cfg.example is committed

## Key paths on this machine
- Diamond bin: /home/pnieves/lscc/diamond/3.14/bin/lin64/
- synthesis, map, par, bitgen batch tools all in: /home/pnieves/lscc/diamond/3.14/bin/lin64/
- Questa: /home/pnieves/lscc/diamond/3.14/questasim/linux_x86_64/vsim
- Diamond version: 3.14

## Build flow (batch mode)

```
make syn   → cd syn/out && synthesis -a ARCH -d DEVICE ... → syn_impl1.ngd
make par   → cd par/out && map ... && par ... → par_impl1_par.ncd
make pgrm  → cd pgrm && bitgen ... → .bit + .jed files
```

## Output layout
- syn/out/ and syn/logs/   ← synthesis artifacts + logs
- par/out/ and par/logs/   ← map/par artifacts + logs
- pgrm/ and pgrm/logs/     ← bitstream (.bit/.jed/.fea) + logs
- sim/out/ and sim/logs/   ← Questa work library + logs
