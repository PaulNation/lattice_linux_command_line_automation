// counter_tb.sv — Questa Sim testbench skeleton
`timescale 1ns/1ps

module counter_tb;
  initial begin
    $dumpfile("trace.vcd");
    $dumpvars(0, counter_tb);
  end
  // Testbench signals
  reg sysclk;
  reg updwn;
  reg id;
  reg reset;
  reg set;
  reg action;
  reg [7:0] data;
  wire [7:0] count;

  // Instantiate DUT
  counter_top dut (
    .sysclk(sysclk),
    .updwn(updwn),
    .id(id),
    .reset(reset),
    .set(set),
    .action(action),
    .data(data),
    .count(count)
  );

  // Clock generation (10ns period)
  always #5 sysclk = !sysclk;

  // Task: Print formatted monitor message
  task show;
    begin
      $display("[%0t] updwn=%b id=%b reset=%b set=%b action=%b data=%h -> count=%h",
                $time, updwn, id, reset, set, action, data, count);
    end
  endtask

  // === Concurrent Assertions (SVA) ===
  // Example: Load via 00110
  // property load_data_p;
  //   @(posedge sysclk)
  //     disable iff (~set)
  //     (reset) |=> (count == data);
  // endproperty
  // assert property (load_data_p) else
  //   $error("Load data assertion failed at t=%0t", $time);

  // // Example: Full scale 0xFF via xxx11
  // property full_scale_p;
  //   @(posedge sysclk)
  //     disable iff (~set)
  //     (action) |=> (count == 8'hFF);
  // endproperty
  // assert property (full_scale_p) else
  //   $error("Full scale assertion failed at t=%0t", $time);

  // // Example: Increment behavior
  // property inc_p;
  //   @(posedge sysclk)
  //     disable iff (~set)
  //     (updwn) |=> (count == $past(count) + 1);
  // endproperty
  // assert property (inc_p) else
  //   $error("Increment assertion failed at t=%0t", $time);

  // // Example: Decrement behavior
  // property dec_p;
  //   @(posedge sysclk)
  //     disable iff (~set)
  //     (id) |=> (count == $past(count) - 1);
  // endproperty
  // assert property (dec_p) else
  //   $error("Decrement assertion failed at t=%0t", $time);

  initial begin
    // Initialize signals
    sysclk = 0;
    updwn = 0;
    id = 0;
    reset = 0;
    set = 0;
    action = 0;
    data = 8'h00;

    $display("=== Starting counter testbench ===");

    // Apply reset
    set = 0;
    @(posedge sysclk);
    show();

    set = 1;
    @(posedge sysclk);
    show();

   
    // Test: increment (updwn=1, id=0, set=1, action=0)
    updwn = 1;
    set = 1;
    repeat(3) begin
      @(posedge sysclk);
      show();
    end

    // Test: decrement (updwn=0, id=1, set=1, action=0)
    updwn = 0;
    set = 1;
    id = 1;
    repeat(3) begin
      @(posedge sysclk);
      show();
    end

    // Test: load data (00110 pattern)
    id = 0;
    reset = 1;
    set = 1;
    action = 0;
    data = 8'h55;
    @(posedge sysclk);
    show();

    // Test: Set to full scale via "xxx11"
    reset = 0;
    set = 1;
    action = 1;
    @(posedge sysclk);
    show();

    // Test: hold behavior
    set = 1;
    action = 0;
    repeat(2) begin
      @(posedge sysclk);
      show();
    end

    $display("=== Testbench completed ===");
    $stop;
  end

endmodule
