module Reciver_Control #(parameter DATA_WIDTH = 8,
                         parameter FRAME_DATA_WIDTH = 10
) (
    input wire clk,
    input wire rst_n,
    input wire data_incoming,
    input wire aligned,
    input wire [FRAME_DATA_WIDTH-1:0] /* verilator lint_off UNUSEDSIGNAL */ data_in /* verilator lint_on UNUSEDSIGNAL */,
    input wire data_ready,
    input wire fifo_empty,
    input wire fifo_full,
    input wire loaded,
    output reg rd_en,
    output reg wr_en,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg load,
    output reg count_align,
    output reg count_data
);

// State definitions for data buffering (SR 2 FIFO)
localparam WRITE_IDLE  = 1'b0;
localparam WRITE2FIFO  = 1'b1;

// State definitions for data buffering (FIFO 2 Display)
localparam READ_IDLE  = 1'b0;
localparam READ_FIFO  = 1'b1;

// State definitions for Rx Data (SR 2 Controller)
localparam RX_IDLE  = 2'b00;
localparam ALIGN  = 2'b01;
localparam COLLECT  = 2'b10;

reg current_state_SR2FIFO, next_state_SR2FIFO;
reg current_state_FIFO2Display, next_state_FIFO2Display;
reg [1:0] current_state_SR2Controller, next_state_SR2Controller;



// FSM State Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state_SR2FIFO <= WRITE_IDLE;
        current_state_FIFO2Display <= READ_IDLE;
        current_state_SR2Controller <= RX_IDLE;
    end
    else begin
        current_state_SR2FIFO <= next_state_SR2FIFO;
        current_state_FIFO2Display <= next_state_FIFO2Display;
        current_state_SR2Controller <= next_state_SR2Controller;
    end
end

// FSM Next State + Output Logic (SR 2 FIFO)
always @(*) begin
    // defaults
    next_state_SR2FIFO = current_state_SR2FIFO;
    wr_en = 1'b0;

    case (current_state_SR2FIFO)
        // -----------------------------------------------------------
        // IDLE
        // -----------------------------------------------------------
        WRITE_IDLE: begin
            if (data_ready && !fifo_full)
                next_state_SR2FIFO = WRITE2FIFO;
        end
        // -----------------------------------------------------------
        // WRITE TO FIFO
        // -----------------------------------------------------------
        WRITE2FIFO: begin
            wr_en = 1'b1;
            next_state_SR2FIFO = WRITE_IDLE;      
              
        end
        default: begin
            next_state_SR2FIFO = WRITE_IDLE;
        end
    endcase
end

// FSM Next State + Output Logic (FIFO 2 Display)
always @(*) begin
    // defaults
    next_state_FIFO2Display = current_state_FIFO2Display;
    rd_en = 1'b0;
    data_out = {DATA_WIDTH{1'b0}};
    load = 1'b0;

    case (current_state_FIFO2Display)
        // -----------------------------------------------------------
        // IDLE
        // -----------------------------------------------------------
        READ_IDLE: begin
            if (!fifo_empty) begin
                next_state_FIFO2Display = READ_FIFO;
                rd_en = 1'b1;
            end
        end
        // -----------------------------------------------------------
        // READ FROM FIFO
        // -----------------------------------------------------------
        READ_FIFO: begin
            load = 1'b1;
            data_out = data_in[FRAME_DATA_WIDTH-2:1];
            if(loaded)
                next_state_FIFO2Display = READ_IDLE;
        end
        default: begin
            next_state_FIFO2Display = READ_IDLE;
        end
    endcase
end

// FSM Next State + Output Logic (SR 2 Controller)
always @(*) begin
    // defaults
    next_state_SR2Controller = current_state_SR2Controller;
    count_align = 1'b0;
    count_data = 1'b0;

    case (current_state_SR2Controller)
        // -----------------------------------------------------------
        // Rx_IDLE
        // -----------------------------------------------------------
        RX_IDLE: begin
            if(data_incoming)
                next_state_SR2Controller = ALIGN;
        end
        // -----------------------------------------------------------
        // Align to middle of data
        // -----------------------------------------------------------
        ALIGN: begin
            count_align = 1'b1;
            if(aligned)
                next_state_SR2Controller = COLLECT;
        end
        // -----------------------------------------------------------
        // Collect all data bits
        // -----------------------------------------------------------
        COLLECT: begin
            count_data = 1'b1;
            if(data_ready)
                next_state_SR2Controller = RX_IDLE;
        end
        default: begin
            next_state_SR2Controller = RX_IDLE;
        end
    endcase
end

endmodule
