module Reciver_Rx (
    input wire clk_c,
    input wire Rx_c,
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [1:0] sw_c,
    /* verilator lint_on UNUSEDSIGNAL */
    output wire [6:0] seg_c,
    output wire dp_c,
    output wire [3:0] an_c
);

parameter b_rate_factor = 651;
parameter Data_Width = 8;
parameter FIFO_Depth = 16;
parameter Frame_Data_Width = 10;

wire sample_tick_c;
wire refresh_clk;

Div_Clk refresh_clk_mod ( .rst_n(sw_c[0]),
                          .clk_in(clk_c),
                          .clk_out(refresh_clk) );

sample_tick_gen #(
        .factor(b_rate_factor)
) baud_rate (
        .rst_n(sw_c[0]),
        .clk_in(clk_c),
        .clk_out(sample_tick_c)
);

wire [Frame_Data_Width-1:0] sr2fifo;
wire ready_flag;
wire data_incoming_flag;
wire aligned_flag;
wire count_align_flag;
wire count_data_flag;

SIPO_SR #(.WIDTH(Frame_Data_Width)) sipo_sr_mod (
    .clk(clk_c),
    .sample_tick(sample_tick_c),
    .rst_n(sw_c[0]),
    .serial_in(Rx_c),
    .parallel_out(sr2fifo),
    .data_ready(ready_flag),
    .data_incoming(data_incoming_flag),
    .aligned(aligned_flag),
    .count_align(count_align_flag),
    .count_data(count_data_flag)
);

wire full_flag;
wire empty_flag;
wire [Frame_Data_Width-1:0] fifo2controller;
wire wr_flag;
wire rd_flag;
wire /* verilator lint_off UNUSEDSIGNAL */ ready2read_flag /* verilator lint_on UNUSEDSIGNAL */;

FIFO #(
    .DATA_WIDTH(Frame_Data_Width),
    .DEPTH(FIFO_Depth)
) Memory_buffer_mod (
    .clk(clk_c),
    .rst_n(sw_c[0]), // Active low reset
    .wr_en(wr_flag),
    .rd_en(rd_flag),
    .data_in(sr2fifo),
    .data_out(fifo2controller),
    .fifo_full(full_flag),
    .fifo_empty(empty_flag),
    .ready2read(ready2read_flag)
);

wire [Data_Width-1:0] controller2display;
wire load_flag;
wire loaded_flag;

Reciver_Control Rx_Control_Mod(
    .clk(clk_c),
    .rst_n(sw_c[0]),
    .data_in(fifo2controller),
    .data_ready(ready_flag),
    .fifo_empty(empty_flag),
    .fifo_full(full_flag),
    .rd_en(rd_flag),
    .wr_en(wr_flag),
    .data_out(controller2display),
    .load(load_flag),
    .loaded(loaded_flag),
    .data_incoming(data_incoming_flag),
    .aligned(aligned_flag),
    .count_align(count_align_flag),
    .count_data(count_data_flag)
);

wire [3:0] an_select_c;
wire [3:0] current_num;

Data_Display display_mod(
    .clk(clk_c),
    .refresh_clk_c(refresh_clk),
    .rst_n(sw_c[0]),
    .load(load_flag),
    .loaded(loaded_flag),
    .data_in(controller2display), //DO NOT LEAVE THIS BLANK
    .an_s(an_select_c),
    .num(current_num)
);

seg_driver display_driver (.clk_connector(refresh_clk),
                            .rst_n(sw_c[0]),
                            .an_select(an_select_c),
                            .num_connector(current_num),
                            .seg_connector(seg_c),
                            .dp_connector(dp_c),
                            .an_connector(an_c));

endmodule
