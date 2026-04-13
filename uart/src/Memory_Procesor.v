module Memory_Procesor #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 13
) (
    input wire fifo_full,
    input wire clk_in,
    input wire start_program,
    input wire rst_n,
    output reg wr_en,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Memory array to store "HELLO WORLD\n" ASCII data
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Address counter
    reg [$clog2(DEPTH)-1:0] addr;

    // Load the memory with characters
    initial begin
        mem[0]  = "H";
        mem[1]  = "E";
        mem[2]  = "L";
        mem[3]  = "L";
        mem[4]  = "O";
        mem[5]  = " ";
        mem[6]  = "W";
        mem[7]  = "O";
        mem[8]  = "R";
        mem[9]  = "L";
        mem[10] = "D";
        mem[11] = 8'h0D;   // CR
        mem[12] = 8'h0A;   // LF
    end

    always @(posedge clk_in or negedge rst_n) begin
        if(!rst_n) begin
            wr_en <= 1'b0;
            data_out <= 0;
            addr <= 0;
        end
        else begin
            if (start_program && !fifo_full && ~(addr == DEPTH)) begin
                wr_en <= 1'b1;              // enable write
                data_out <= mem[addr];      // output next byte

                // increment address until we reach the end
                // if (addr == DEPTH - 1)
                //     addr <= 0;
                // else
                    addr <= addr + 1;
            end else begin
                wr_en <= 1'b0;
                data_out <= mem[addr];
                addr <= addr;
            end
        end
    end
endmodule
