module Transmit_Control #(
    parameter DATA_IN_WIDTH = 8,
    parameter FRAME_DATA_WIDTH = 10
) (
    input wire rst_n,
    input wire clk,
    input wire data_loaded,
    input wire ready2read,
    input wire fifo_empty,
    input wire shift_finish,
    input wire [DATA_IN_WIDTH-1:0] data_in,
    output reg rd_en,
    output reg load,
    output reg [FRAME_DATA_WIDTH-1:0] data_out
);

// State definitions
localparam STATE_IDLE      = 2'b00;
localparam STATE_TRANSMIT  = 2'b01;
localparam READ_MEM        = 2'b10;
localparam WAIT_FOR_SHIFT  = 2'b11;

reg [1:0] current_state, next_state;

// FSM State Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_state <= STATE_IDLE;
    else
        current_state <= next_state;
end

// FSM Next State + Output Logic
always @(*) begin

    // defaults
    next_state = current_state;
    rd_en = 1'b0;
    load = 1'b0;
    data_out = {FRAME_DATA_WIDTH{1'b0}};

    case (current_state)

        // -----------------------------------------------------------
        // IDLE
        // -----------------------------------------------------------
        STATE_IDLE: begin
            if (!fifo_empty)
                next_state = READ_MEM;
        end

        // -----------------------------------------------------------
        // READ FROM FIFO
        // -----------------------------------------------------------
        READ_MEM: begin
            if(ready2read) begin
                rd_en = 1'b1;
                next_state = STATE_TRANSMIT;      
            end  
        end

        // -----------------------------------------------------------
        // TRANSMIT FRAME OUT
        // -----------------------------------------------------------
        STATE_TRANSMIT: begin //hold this state until loaded
            // Output UART frame: {stop_bit, data, start_bit}
            if(data_loaded) begin
                next_state = WAIT_FOR_SHIFT;
            end
            else begin
                data_out = {1'b1, data_in, 1'b0};
                load = 1'b1;
                // start_count = 1'b1;
            end
        end

        // -----------------------------------------------------------
        // WAIT UNTIL TRANSMIT SHIFT IS DONE
        // -----------------------------------------------------------
        WAIT_FOR_SHIFT: begin
            if (shift_finish)
                next_state = STATE_IDLE;
        end

        default: begin
            next_state = STATE_IDLE;
        end
    endcase
end

endmodule
