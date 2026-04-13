module Data_Display #(parameter DATA_WIDTH = 8) (
    input wire clk,
    input wire refresh_clk_c,
    input wire rst_n,
    input wire load,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [3:0] an_s,
    output reg [3:0] num,
    output reg loaded
);

    reg [DATA_WIDTH-1:0] data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 0;
            loaded <= 1'b0;
        end else begin
            if(load) begin
                data <= data_in;
                loaded <= 1'b1;
            end
            else begin
                data <= data; 
                loaded <= 1'b0;
            end
        end
    end

    reg count;

    always @(posedge refresh_clk_c or negedge rst_n) begin
        if (!rst_n) begin
            an_s <= 4'b0011;
            num <= 0;
            count <= 0;
        end else begin
            if(count == 0) begin
                an_s <= 4'b0111;
                num <= data[DATA_WIDTH-1:4];
                count <= count + 1;
            end
            else begin
                an_s <= 4'b1011;
                num <= data[3:0];
                count <= 0;
            end
        end
    end

endmodule
