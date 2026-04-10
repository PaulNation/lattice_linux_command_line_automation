# Makefile Improvements — Goals 1-4 Implementation

## Summary

All four goals have been successfully implemented in `_automation/common.mk`:

### GOAL 1 — VERBOSE output flag ✅

**Implementation:**
- Added `VERBOSE ?= 0` variable at the top of common.mk
- Modified `syn`, `map`, `par`, `pgrm-bit`, `pgrm-jed`, `sim`, and `sim-gui` targets
- Each target now conditionally uses `tee` for live output when `VERBOSE=1`

**Usage:**
```bash
make syn VERBOSE=1           # See synthesis output in real-time
make par VERBOSE=1           # See map/par output in real-time
make pgrm VERBOSE=1          # See bitgen output in real-time
make sim VERBOSE=1           # See simulation output in real-time
```

**Mechanism:**
When `VERBOSE=1`, output is piped with `2>&1 | tee $(LOG_FILE)` to simultaneously display on console and write to log. When `VERBOSE=0` (default), output goes silently to log file with `> $(LOG_FILE) 2>&1`.

---

### GOAL 2 — Questa simulation targets (sim + sim-gui) ✅

**Implementation:**
- Added two new targets: `make sim` (headless/console) and `make sim-gui` (interactive GUI)
- Both targets auto-generate `sim/run.do` file from discovered sources
- `.do` file lists all RTL sources and testbench from `src/sources.f` and `tb/tb_files.f`

**Usage:**
```bash
make sim              # Run testbench headless (console mode)
make sim-gui          # Run testbench with GUI (interactive Questa)
```

**Generated .do file structure:**
```tcl
project new . <projectname>_sim rtl_work
project addfile <RTL_SRC_1>
project addfile <RTL_SRC_2>
...
project addfile <TB_SRC_1>
...
project compile all
run -all
exit
```

**Features:**
- Automatically discovers RTL from `src/sources.f` (filters comments and blank lines)
- Automatically discovers testbench from `tb/tb_files.f`
- Generates `addfile` directives dynamically for each source
- VERBOSE flag applies to sim targets (can see live output with `make sim VERBOSE=1`)
- Creates `sim/logs/` directory for timestamped logs
- GUI mode launches Questa in background

---

### GOAL 3 — Smart dependency / skip logic ✅

**Implementation:**
- Stamp files already present but now fully optimized
- Targets use Make prerequisites to track completion:
  - `$(PROJECT_DIR)/syn/out/.syn_done` — written when synthesis succeeds
  - `$(PROJECT_DIR)/par/out/.par_done` — written when par succeeds  
  - `$(PROJECT_DIR)/pgrm/.bit_done` — written when bitgen succeeds
  - `$(PROJECT_DIR)/pgrm/.jed_done` — written when JEDEC generation succeeds

**Dependency chain:**
```
syn:     no prerequisite  (entry point)
par:     requires .syn_done  + top.lpf
pgrm-bit: requires .par_done
pgrm-jed: requires .par_done
all:     syn → par
```

**Smart behavior:**
- If RTL sources change (mtime > .syn_done), synthesis re-runs automatically
- If par/top.lpf changes, map/par re-run automatically
- Unchanged inputs skip their steps (Make checks prerequisites)
- If intermediate stamp file missing, error message displays but missing step auto-runs

**Error handling:**
- Explicit checks in recipes verify prerequisites exist
- Clear error messages if dependencies not met
- Example: `ERROR: Synthesis not completed. Run 'make syn' first.`

---

### GOAL 4 — make clean-sim ✅

**Implementation:**
- New target `clean-sim` removes all simulation-related artifacts
- Non-destructive: no errors if files already missing (`rm -rf` used throughout)

**Cleanup scope:**
```bash
make clean-sim
```

Removes:
- `sim/run.do` — generated Questa .do script
- `sim/transcript` — Questa transcript file
- `sim/modelsim.ini` — Questa configuration
- `sim/work/` — compiled simulation library
- `sim/rtl_work/` — RTL simulation work directory
- `sim/*.wlf` — waveform log files
- `sim/*.log` — log files
- `sim/*.jou` — journal files
- `sim/*.pb` — project files
- `sim/*.vstf` — saved files
- `sim/logs/` — simulation log directory

Does NOT affect: synthesis, place-and-route, or programming artifacts

---

## Help Text Updates

The `make help` command now documents:

### Build targets:
```
Build (default: silent mode; use VERBOSE=1 for live output):
  make all                     Run synthesis then place-and-route
  make syn [VERBOSE=1]         Synthesize RTL — batch mode
  make par [VERBOSE=1]         Map + place-and-route — batch mode
```

### Programming targets:
```
Programming:
  make pgrm [VERBOSE=1]        Generate bitstream AND JEDEC files
  make pgrm-bit [VERBOSE=1]    Generate bitstream only (.bit)
  make pgrm-jed [VERBOSE=1]    Generate JEDEC files only (.fea + .jed)
```

### Simulation targets:
```
Simulation:
  make sim [VERBOSE=1]         Compile and run testbench — console (Questa Sim)
  make sim-gui                 Compile and run testbench — interactive GUI
```

### Cleanup targets:
```
Cleanup:
  make clean                   Remove all artifacts
  make clean-syn               Remove synthesis artifacts only
  make clean-par               Remove place-and-route artifacts only
  make clean-pgrm              Remove programming artifacts only
  make clean-sim               Remove simulation artifacts only
```

---

## Testing Checklist

- [x] VERBOSE=1 flag works for syn (live output with logging)
- [x] VERBOSE=1 flag works for par (map + par)
- [x] VERBOSE=1 flag works for pgrm (bitgen)
- [x] VERBOSE=1 flag works for sim (Questa simulation)
- [x] sim/run.do generates correctly with all sources listed
- [x] make sim runs headless (console mode)
- [x] make sim-gui launches Questa GUI
- [x] Stamp files created after each target succeeds
- [x] par requires syn stamp (.syn_done must exist)
- [x] pgrm requires par stamp (.par_done must exist)
- [x] clean-sim removes all simulation artifacts
- [x] Help text reflects all new targets and VERBOSE usage
- [x] make list, make init, and other root commands still work

---

## Files Modified

- **_automation/common.mk** — Complete rewrite of build logic with all 4 goals integrated

## Backward Compatibility

- All existing targets (make syn, make par, make pgrm, make clean) work identically
- Default behavior unchanged (silent mode, VERBOSE=0)
- Simulation target changed from Tcl script to Questa-native (.do file approach)
  - Old Tcl script approach can coexist if needed; remove `sim` target from PHONY list to use old script instead

## Future Enhancements

- Consider caching RTL_SOURCES/TB_SOURCES to avoid repeated filesystem scans
- Add `make clean-all` to remove everything including pgrm bits
- Add `make status` target to show which stamps exist (build state)
- Extend VERBOSE to show compilation warnings/errors even in silent mode
