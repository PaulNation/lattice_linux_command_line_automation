module seg_driver (
    input wire clk_connector,
    input wire rst_n,
    input wire [3:0] an_select,
    input wire [3:0] num_connector,
    output reg [6:0] seg_connector,
    output reg dp_connector,
    output reg [3:0] an_connector
);
    
    always @(posedge clk_connector or negedge rst_n) begin
        if(!rst_n) begin
            seg_connector <= 7'b1111111;  // all segments OFF
            an_connector <= 4'b1111;     // all digits disabled
            dp_connector <= 1'b1;        // dp OFF
        end
        else begin
            if (num_connector == 0) begin
                seg_connector <= 7'b1000000;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 1) begin
                seg_connector <= 7'b1111001;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 2) begin
                seg_connector <= 7'b0100100;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 3) begin
                seg_connector <= 7'b0110000;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 4) begin
                seg_connector <= 7'b0011001;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 5) begin
                seg_connector <= 7'b0010010;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 6) begin
                seg_connector <= 7'b0000010;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 7) begin
                seg_connector <= 7'b1111000;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 8) begin
                seg_connector <= 7'b0000000;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 9) begin
                seg_connector <= 7'b0010000;
                an_connector <= an_select;
                dp_connector <= 1;
            end
            if (num_connector == 10) begin
                seg_connector <= 7'b0001000;
                an_connector <= an_select;
                dp_connector <= 0;
            end
            if (num_connector == 11) begin
                seg_connector <= 7'b0000000;
                an_connector <= an_select;
                dp_connector <= 0;
            end
            if (num_connector == 12) begin
                seg_connector <= 7'b1000110;
                an_connector <= an_select;
                dp_connector <= 0;
            end
            if (num_connector == 13) begin
                seg_connector <= 7'b1000000;
                an_connector <= an_select;
                dp_connector <= 0;
            end
            if (num_connector == 14) begin
                seg_connector <= 7'b0000110;
                an_connector <= an_select;
                dp_connector <= 0;
            end
            if (num_connector == 15) begin
                seg_connector <= 7'b0001110;
                an_connector <= an_select;
                dp_connector <= 0;
            end
        end
    end

endmodule
