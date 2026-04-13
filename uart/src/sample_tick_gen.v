module sample_tick_gen #(
        parameter factor = 100000
    ) 
    (
        input wire rst_n,
        input wire clk_in,
        output reg clk_out
);

localparam COUNT_WIDTH = $clog2(factor);  // number of bits required for "factor"

reg [COUNT_WIDTH-1:0] count;

always @(posedge clk_in or negedge rst_n) begin
    if(!rst_n) begin
        clk_out <= 0;
        count <= 0;
    end
    else begin
        if(count == factor-1) begin
            clk_out <= 1;
            count <= 0;
        end
        else begin
            count <= count + 1;
            clk_out <= 0;
        end
    end
end

endmodule
