module Transmit_Tx (
    input wire clk_c,
    input wire [1:0] sw_c,
    output wire RsTx_c
);

parameter b_rate_factor = 78;  // 12MHz / (16 * 9600 baud) = 78.125
parameter Data_Width = 8;
parameter Depth = 13;
parameter FIFO_Depth = 16;
parameter Frame_Data_Width = 10;

wire sample_tick;
wire full_flag;
wire [Data_Width-1:0] data_Mp2Buffer;
wire ena_Mp2Buffer;

sample_tick_gen #(
        .factor(b_rate_factor)
) baud_rate (
        .rst_n(sw_c[0]),
        .clk_in(clk_c),
        .clk_out(sample_tick)
);

Memory_Procesor #(
    .DATA_WIDTH(Data_Width),
    .DEPTH(Depth)
) main_proccesor (
    .fifo_full(full_flag),
    .clk_in(clk_c),
    .start_program(sw_c[1]),
    .rst_n(sw_c[0]),
    .wr_en(ena_Mp2Buffer),
    .data_out(data_Mp2Buffer)
);

wire read_flag;
wire empty_flag;
wire [Data_Width-1:0] FIFO2Controller;
wire ready2read_flag;

FIFO #(
    .DATA_WIDTH(Data_Width),
    .DEPTH(FIFO_Depth)
) memory_buffer (
    .clk(clk_c),
    .rst_n(sw_c[0]),
    .wr_en(ena_Mp2Buffer),
    .rd_en(read_flag),
    .data_in(data_Mp2Buffer),
    .data_out(FIFO2Controller),
    .fifo_full(full_flag),
    .fifo_empty(empty_flag),
    .ready2read(ready2read_flag)
);

wire load_flag;
wire [Frame_Data_Width-1:0] controller2sr;
wire loaded_flag;
wire done_flag;

Transmit_Control #(
    .DATA_IN_WIDTH(Data_Width),
    .FRAME_DATA_WIDTH(Frame_Data_Width)
) tx_controller (
    .rst_n(sw_c[0]),
    .clk(clk_c),
    .data_loaded(loaded_flag),
    .ready2read(ready2read_flag),
    .fifo_empty(empty_flag),
    .shift_finish(done_flag),
    .data_in(FIFO2Controller),
    .rd_en(read_flag),
    .load(load_flag),
    .data_out(controller2sr)
);

PISO_SR #(
    .DATA_WIDTH(Frame_Data_Width)
) shift_r (
  .load(load_flag),       // Load signal
  .clk(clk_c),        // Clock signal
  .rst_n(sw_c[0]),        // Reset signal
  .sample_tick(sample_tick),   // <-- new oversampling input
  .data_in(controller2sr), // 10-bit parallel data input
  .data_loaded(loaded_flag),
  .tx_out(RsTx_c), // Serial data output
  .tx_done(done_flag)
);

endmodule
