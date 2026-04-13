module PISO_SR #(
    parameter DATA_WIDTH = 10,            // Should be 10 for 1 start + 8 data + 1 stop
    parameter TICKS_PER_BIT = 16          // Oversampling
)(      
    input wire clk,                       // System clock
    input wire rst_n,                     // Reset
    input wire load,                      // Load signal
    input wire sample_tick,               // 16x baud tick
    input wire [DATA_WIDTH-1:0] data_in,  // Frame: {stop, data[7:0], start}
    
    output reg data_loaded,               // Goes high for 1 cycle on load
    output reg tx_out,                    // Serial output
    output reg tx_done                    // High for 1 cycle after full frame completes
);

    // Internal registers
    reg [DATA_WIDTH-1:0] /* verilator lint_off UNUSEDSIGNAL */ sh_reg /* verilator lint_on UNUSEDSIGNAL */; // Shift register
    reg [4:0] tick_count;        // Counts 0..15  (oversampling ticks)
    reg [$clog2(DATA_WIDTH):0] bit_count; // Counts bits transmitted

    // Main logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sh_reg     <= {DATA_WIDTH{1'b1}};
            tx_out     <= 1'b1;
            data_loaded <= 1'b0;
            tx_done    <= 1'b0;
            tick_count <= 0;
            bit_count  <= 0;

        end else begin
            data_loaded <= 1'b0;  // Default
            tx_done     <= 1'b0;  // Default

            if (load) begin
                // Load full 10-bit frame: {stop, data[7:0], start}
                sh_reg <= data_in;
                tx_out <= data_in[0];   // Send start bit first
                tick_count <= 0;
                bit_count <= 0;
                data_loaded <= 1'b1;

            end else if (sample_tick) begin
                // Count 16× oversampling ticks
                if (tick_count == (TICKS_PER_BIT - 1)) begin
                    tick_count <= 0;

                    // Shift one data bit
                    sh_reg <= {1'b1, sh_reg[DATA_WIDTH-1:1]};
                    tx_out <= sh_reg[1];   // Next bit goes to output
                    bit_count <= bit_count + 1;

                    // Completed transmission?
                    if (bit_count == DATA_WIDTH-1) begin
                        tx_done <= 1'b1;
                    end
                end else begin
                    tick_count <= tick_count + 1;
                end
            end
        end
    end

endmodule
