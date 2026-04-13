module FIFO #(
    parameter DATA_WIDTH = 10,
    parameter DEPTH = 12
) (
    input wire clk,
    input wire rst_n, // Active low reset
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire fifo_full,
    output wire fifo_empty,
    output wire ready2read
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;
    reg [PTR_WIDTH:0] count;  // one bit wider

    assign fifo_full  = (count == DEPTH);
    assign fifo_empty = (count == 0);
    assign ready2read = !wr_en;
    // **Unified Read + Write Logic**
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            data_out <= 0;
            count    <= 0;
        end else begin

            // WRITE
            if (wr_en && !fifo_full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
            end

            // READ
            else if (rd_en && !fifo_empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end

            // UPDATE COUNT (only once!)
            case ({wr_en && !fifo_full, rd_en && !fifo_empty})
                2'b10: count <= count + 1; // write only
                2'b01: count <= count - 1; // read only
                // 2'b11: count unchanged (simultaneous read + write)
                default: count <= count; 
            endcase
        end
    end
endmodule
