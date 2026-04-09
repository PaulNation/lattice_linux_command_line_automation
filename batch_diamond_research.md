
#Synth Batch command - outputs xo2_proj_impll.ngd
synthesis -a "MachXO3D" -s 5 -t CABGA256 -d LCMXO3D-9400HC -top fpga_uart_top -ver ../src/fpga_uart_top.v -ngd xo2_proj_impll.ngd

#PAR batch command workflow - map outputs "syn_out.ncd" -> par outputs 5_1.ncd
# example map command that works
map -a "MachXO3D" -p LCMXO3D-9400HC -t CABGA256 -s 5 -oc Commercial ../syn/xo2_proj_impll.ngd -mp "xo2_proj_impll.mrp" -o "xo2_proj_impll_map.ncd" -pr "xo2_proj_impll.prf" -lpf "top.lpf" -c 0

#map args
[pnieves@PaulsDesktop par] (main…) ❯ map
map:  version Diamond (64-bit) 3.14.0.75.2

Usage: map [ -h <arch> | [options] <infile[.ngd]> [-o <outfile[.ncd]>] [<prffile[.prf]>] ]

#example par command that works based on the previous map command -> outputs 5_1.ncd
par -w -l 5 -i 6 -t 1 -c 0 -e 0 -gui -exp parUseNBR=1:parCDP=0:parCDR=0:parPathBased=OFF:parASE=1 xo2_proj_impll_map.ncd 5_1.ncd proj_impll.prf

#par args
[pnieves@PaulsDesktop par] (main…) ❯ par
par:  version Diamond (64-bit) 3.14.0.75.2
Usage: par ] [-k] [-p] [-r] [-i  <routepasses:0,2000>] [-c <costpasses:0,20>] [-e| -d <delaypasses:0,100>] [-x] [-a] [-l <level:1,5>] [-inc] [-icf <icffile[.icf]>] [-ref <reffile[.ncd]>] [-g <guidefile[.ncd]>] [-gv] [-x] [-a] [-l <level:1,5>] [-mf <matchingfactor:0,100>] [-n <iterations:0,100>] [-t <costtable:1,100>] [-sp <speedgrade>] [-s <savebest:1,100>] [-w] [-y] [-m [<nodelistfile>]] [-exp <explorerstring>] [-io] [-ta <ta_string>] [-mc] [-assemble] [-stopzero] [-pe] [-fc] [-cs <clockskewstrategy:1,3>] <infile[.ncd]> <outfile> {<preffile[.prf]>}
 
Where:
   -assemble  = (Modular Design) Assemble top-level design and the
         implemented modules into one design.
   -c  = Run n cleanup passes of the router.
         Default: 1.
   -cs = Turn on clock skew minimization with given strategy on non-global
         clocks or selected clocks
   -d  = Run n delay based cleanup passes of the router, n >= 0.
         Default: 0.
   -e  = Run n delay based cleanup passes of the router if there
         are 0 unrouted, n >= 0.
         Default: 0.
   -exp= Explorer string, to turn on/off special place and route options.  
   -f  = Read par command line arguments & switches from file.
   -fc = Freedom chip flow, will insert scan chains into design.
   -g  = Use a guide file to place and route against
         1. Keep matching block names.
         2. Keep matching net names/pins.
   -gv = List matched comps/macros/signals in guided par report file.
   -i  = Run n iterations of the router.
         Default: Run until router decides it will not complete
         without diverging.
   -io = io assistant flow.
   -k  = Skip constructive placement. Run optimize placement
         and then enter the router.
         Note: Use -k -p to do reentrant routing.
   -l  = Effort Level. Level 5 is maximum effort.
         Default: 5.
   -m  = Multi task par run.  File "<node list file>",
         contains a list of node names to run the jobs on.
   -mc = (Modular Design) Compile each module.
   -mf = Matching factor.
         Default: 100
   -n  = Iterations at this level.  Use "-n 0" to run until 
         fully routed.  See Note under "-a" option.
         Default: 1.
   -stopzero = stop multiple seed router run when time score reaches zero.
         Maximum number of seeds is set by -n option. If -n not used, or 
         "-n 0" is used, will run up to 99 seeds.
   -p  = Don't run placement.
   -pe = Error out if there're any preference errors.
   -r  = Don't run router.
   -s  = Save "n" best results for this run.
         Default:  Save All.
   -sp = Change performance grade.
         Default:  Keep current performance grade.
   -t  = Start at this placer cost table entry.
         Default: 1. 
   -w  = Overwrite.  Allows overwrite of an existing
         file (including input file).  If specified output is a 
         directory, allows files in directory to be overwritten.
   -x  = Ignore Timing preferences in preference file.
   -y  = Create .dly file and the delay statistics at end of .par file

   <infile>   = Name of input NCD file.
   <outfile>  = Name of output NCD file or output directory.
                Use format "<outfile>.ncd" or "<outfile>.dir".
   <preffile> = Name of preference file.

#generating bitstream and jedec command that work
#bitstream -> outputs 5_1.bit
bitgen -w "5_1.ncd" "xo2_proj_impll.prf"
#jedec -> outputs Jedec File [0]: 5_1.fea, Jedec File [1]: 5_1_a.jed
bitgen -w "5_1.ncd" -jedec "xo2_proj_impll.prf"

#bitgen args:
[pnieves@PaulsDesktop par] (main…) ❯ bitgen
Usage: bitgen [-help <arch>] [-J w <infile1.ncd> {<infile2.ncd>} ][-J r] <infile[.ncd]> [<outfile>] [<prffile[.prf]>].