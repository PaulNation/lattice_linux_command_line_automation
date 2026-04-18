prj_project new -name "counter_top" -impl "impl1" -dev LCMXO3D-9400HC-5BG256C -synthesis "synplify" -lpf "/home/pnieves/fpga-workspace/counter/export/impl1/source/top.lpf"
prj_src add "/home/pnieves/fpga-workspace/counter/export/impl1/source/counter_top.v"
prj_src add "/home/pnieves/fpga-workspace/counter/export/impl1/source/counter_tb.sv"
prj_src syn_sim -src "/home/pnieves/fpga-workspace/counter/export/impl1/source/counter_tb.sv" SimulateOnly
prj_project save
prj_project archive -includeAll "/home/pnieves/fpga-workspace/counter/export/counter_export.zip"
exit
