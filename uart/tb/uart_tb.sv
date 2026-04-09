// uart_tb.sv — Questa Sim testbench skeleton
`timescale 1ns/1ps

module uart_tb;

    logic clk   = 0;
    logic rst_n = 0;

    uart_top dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    always #5 clk = ~clk;  // 100 MHz

    initial begin
        #20 rst_n = 1;
        // TODO: add stimulus
        #1000;
        $display("SIM DONE");
        $finish;
    end

endmodule
