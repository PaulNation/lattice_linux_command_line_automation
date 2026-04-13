module SIPO_SR #(parameter WIDTH = 10) (
    input clk,
    input rst_n,
    input sample_tick,
    input serial_in,
    input wire count_align,
    input wire count_data,
    output reg [WIDTH-1:0] parallel_out,
    output reg data_ready,
    output reg data_incoming,
    output reg aligned
);

    //data flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_incoming <= 1'b0; // Reset
        end else begin
            if(~serial_in)
                data_incoming <= 1'b1;
            else
                data_incoming <= 1'b0; 
        end
    end

    localparam half_of_oversample = $clog2(7);
    reg [half_of_oversample-1:0] cur_cnt_align;

    //align
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aligned <= 1'b0; // Reset
            cur_cnt_align <= 0;
        end else begin
            if(sample_tick && count_align)begin
                if(cur_cnt_align == 7) begin
                    aligned <= 1'b1;
                    cur_cnt_align <= 0;
                end
                else begin
                    cur_cnt_align <= cur_cnt_align + 1;
                    aligned <= 1'b0; 
                end
            end
            else begin
                cur_cnt_align <= cur_cnt_align;
                aligned <= 1'b0; 
            end
        end
    end

    localparam oversample = $clog2(16);
    localparam bit_cnt_size = $clog2(WIDTH);
    reg [oversample-1:0] cur_cnt_tick;
    reg [bit_cnt_size-1:0] bit_cnt;
    //Count data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_ready <= 1'b0; // Reset
            cur_cnt_tick <= 0;
            bit_cnt <= 0;
            parallel_out <= {WIDTH{1'b1}};
        end else begin
            if(bit_cnt == 9) begin
                parallel_out <= parallel_out;
                data_ready <= 1'b1;
                bit_cnt <= 0;
            end
            else if(sample_tick && count_data)begin
                if(cur_cnt_tick == 15) begin
                    cur_cnt_tick <= 0;
                    parallel_out <= {serial_in, parallel_out[WIDTH-1:1]};
                    bit_cnt <= bit_cnt + 1;
                end
                else begin
                    cur_cnt_tick <= cur_cnt_tick + 1;
                end
            end
            else begin
                cur_cnt_tick <= cur_cnt_tick;
                bit_cnt <= bit_cnt;
                data_ready <= 1'b0; 
            end
        end
    end

endmodule
