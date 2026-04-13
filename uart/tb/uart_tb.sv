// uart_tb.sv — Questa Sim testbench skeleton
`timescale 1ns/1ps

module uart_tb;
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
    // Testbench signals
    reg clk;
    reg [1:0] sw;
    wire RsTx;
    wire baud_clk;
    wire b_rate;
    wire [6:0] seg;
    wire dp;
    wire [3:0] an;
    wire [1:0] led;
    wire debug;
    reg RsRx;
    /* verilator lint_on UNDRIVEN */
    /* verilator lint_on UNUSEDSIGNAL */
    
    // Instantiate DUT
    uart_top dut (
        .clk(clk),
        .sw(sw),
        .RsTx(RsTx),
        .seg(seg),
        .dp(dp),
        .an(an),
        .led(led),
        .RsRx(RsRx),
        .debug(debug)
    );

    // Clock generation: 50 MHz clock (20 ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    parameter b_rate_factor = 10417;
    Div_Clk #(
        .factor(b_rate_factor)
        ) helper (
            .rst_n(sw[0]),
            .clk_in(clk),
            .clk_out(b_rate)
        );

    // Initial stimulus
    initial begin
        // VCD dump for waveform view (optional)
        // $dumpfile("top_tb.vcd");
        // $dumpvars(0, top_tb);

        // Reset all switches
        sw = 2'b00;          // sw[0] = reset, sw[1] = start_program = 0
        #200;

        // Release reset
        sw[0] = 1;
        #200;

        // Trigger the Memory Processor start
        sw[1] = 1;
        // #100;

        // sw[1] = 0; // Remove start pulse

        // Let system run to transmit bytes
        repeat(20000) @(posedge b_rate);

        $stop;
    end

    // UART Output Monitor
    // initial begin
    //     $display("Time\tRsRx");
    //     $monitor("%0t\t%b", $time, RsRx);
    // end

endmodule
