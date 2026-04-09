// Verilog netlist produced by program LSE :  version Diamond (64-bit) 3.14.0.75.2
// Netlist written on Thu Apr  9 15:39:07 2026
//
// Verilog Description of module fpga_uart_top
//

module fpga_uart_top (sysclk, updwn, id, reset, set, action, data, 
            count) /* synthesis syn_module_defined=1 */ ;   // ../src/fpga_uart_top.v(5[8:21])
    input sysclk;   // ../src/fpga_uart_top.v(6[16:22])
    input updwn;   // ../src/fpga_uart_top.v(7[16:21])
    input id;   // ../src/fpga_uart_top.v(8[16:18])
    input reset;   // ../src/fpga_uart_top.v(9[16:21])
    input set;   // ../src/fpga_uart_top.v(10[16:19])
    input action;   // ../src/fpga_uart_top.v(11[16:22])
    input [7:0]data;   // ../src/fpga_uart_top.v(12[22:26])
    output [7:0]count;   // ../src/fpga_uart_top.v(13[22:27])
    
    wire sysclk_c /* synthesis is_clock=1, SET_AS_NETWORK=sysclk_c */ ;   // ../src/fpga_uart_top.v(6[16:22])
    
    wire VCC_net, GND_net, updwn_c, id_c, reset_c, set_c, action_c, 
        data_c_7, data_c_6, data_c_5, data_c_4, data_c_3, data_c_2, 
        data_c_1, data_c_0, count_c_7, count_c_6, count_c_5, count_c_4, 
        count_c_3, count_c_2, count_c_1, count_c_0, sysclk_c_enable_8, 
        n6, n132, n112, n113, n114, n115, n116, n117, n118, 
        n139, n140, n141, n119, n142, n143, n144, n145, n146, 
        n289, n288, n287, n286, n246;
    
    VLO i159 (.Z(GND_net));
    LUT4 i154_2_lut (.A(data_c_3), .B(reset_c), .Z(n116)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i154_2_lut.init = 16'hbbbb;
    OB count_pad_3 (.I(count_c_3), .O(count[3]));   // ../src/fpga_uart_top.v(13[22:27])
    OB count_pad_4 (.I(count_c_4), .O(count[4]));   // ../src/fpga_uart_top.v(13[22:27])
    IB id_pad (.I(id), .O(id_c));   // ../src/fpga_uart_top.v(8[16:18])
    OB count_pad_6 (.I(count_c_6), .O(count[6]));   // ../src/fpga_uart_top.v(13[22:27])
    LUT4 i190_3_lut_4_lut (.A(id_c), .B(updwn_c), .C(action_c), .D(reset_c), 
         .Z(n246)) /* synthesis lut_function=(A+(B+(C (D)+!C !(D)))) */ ;
    defparam i190_3_lut_4_lut.init = 16'hfeef;
    IB updwn_pad (.I(updwn), .O(updwn_c));   // ../src/fpga_uart_top.v(7[16:21])
    IB sysclk_pad (.I(sysclk), .O(sysclk_c));   // ../src/fpga_uart_top.v(6[16:22])
    OB count_pad_0 (.I(count_c_0), .O(count[0]));   // ../src/fpga_uart_top.v(13[22:27])
    LUT4 i158_2_lut (.A(data_c_7), .B(reset_c), .Z(n112)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i158_2_lut.init = 16'hbbbb;
    OB count_pad_1 (.I(count_c_1), .O(count[1]));   // ../src/fpga_uart_top.v(13[22:27])
    VHI i203 (.Z(VCC_net));
    OB count_pad_2 (.I(count_c_2), .O(count[2]));   // ../src/fpga_uart_top.v(13[22:27])
    FD1P3AX count_i0_i2 (.D(n145), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_1));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i2.GSR = "ENABLED";
    GSR GSR_INST (.GSR(set_c));
    OB count_pad_7 (.I(count_c_7), .O(count[7]));   // ../src/fpga_uart_top.v(13[22:27])
    TSALL TSALL_INST (.TSALL(GND_net));
    OB count_pad_5 (.I(count_c_5), .O(count[5]));   // ../src/fpga_uart_top.v(13[22:27])
    IB reset_pad (.I(reset), .O(reset_c));   // ../src/fpga_uart_top.v(9[16:21])
    IB set_pad (.I(set), .O(set_c));   // ../src/fpga_uart_top.v(10[16:19])
    IB action_pad (.I(action), .O(action_c));   // ../src/fpga_uart_top.v(11[16:22])
    IB data_pad_7 (.I(data[7]), .O(data_c_7));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_6 (.I(data[6]), .O(data_c_6));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_5 (.I(data[5]), .O(data_c_5));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_4 (.I(data[4]), .O(data_c_4));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_3 (.I(data[3]), .O(data_c_3));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_2 (.I(data[2]), .O(data_c_2));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_1 (.I(data[1]), .O(data_c_1));   // ../src/fpga_uart_top.v(12[22:26])
    IB data_pad_0 (.I(data[0]), .O(data_c_0));   // ../src/fpga_uart_top.v(12[22:26])
    CCU2D add_48_9 (.A0(updwn_c), .B0(n246), .C0(n113), .D0(count_c_6), 
          .A1(updwn_c), .B1(n246), .C1(n112), .D1(count_c_7), .CIN(n289), 
          .S0(n140), .S1(n139));   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam add_48_9.INIT0 = 16'hb874;
    defparam add_48_9.INIT1 = 16'hb874;
    defparam add_48_9.INJECT1_0 = "NO";
    defparam add_48_9.INJECT1_1 = "NO";
    CCU2D add_48_7 (.A0(updwn_c), .B0(n246), .C0(n115), .D0(count_c_4), 
          .A1(updwn_c), .B1(n246), .C1(n114), .D1(count_c_5), .CIN(n288), 
          .COUT(n289), .S0(n142), .S1(n141));   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam add_48_7.INIT0 = 16'hb874;
    defparam add_48_7.INIT1 = 16'hb874;
    defparam add_48_7.INJECT1_0 = "NO";
    defparam add_48_7.INJECT1_1 = "NO";
    CCU2D add_48_5 (.A0(updwn_c), .B0(n246), .C0(n117), .D0(count_c_2), 
          .A1(updwn_c), .B1(n246), .C1(n116), .D1(count_c_3), .CIN(n287), 
          .COUT(n288), .S0(n144), .S1(n143));   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam add_48_5.INIT0 = 16'hb874;
    defparam add_48_5.INIT1 = 16'hb874;
    defparam add_48_5.INJECT1_0 = "NO";
    defparam add_48_5.INJECT1_1 = "NO";
    CCU2D add_48_3 (.A0(updwn_c), .B0(n246), .C0(n119), .D0(count_c_0), 
          .A1(updwn_c), .B1(n246), .C1(n118), .D1(count_c_1), .CIN(n286), 
          .COUT(n287), .S0(n146), .S1(n145));   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam add_48_3.INIT0 = 16'h74b8;
    defparam add_48_3.INIT1 = 16'hb874;
    defparam add_48_3.INJECT1_0 = "NO";
    defparam add_48_3.INJECT1_1 = "NO";
    CCU2D add_48_1 (.A0(GND_net), .B0(GND_net), .C0(GND_net), .D0(GND_net), 
          .A1(action_c), .B1(reset_c), .C1(n6), .D1(n132), .COUT(n286));   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam add_48_1.INIT0 = 16'hF000;
    defparam add_48_1.INIT1 = 16'h06ff;
    defparam add_48_1.INJECT1_0 = "NO";
    defparam add_48_1.INJECT1_1 = "NO";
    FD1P3AX count_i0_i3 (.D(n144), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_2));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i3.GSR = "ENABLED";
    FD1P3AX count_i0_i4 (.D(n143), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_3));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i4.GSR = "ENABLED";
    FD1P3AX count_i0_i5 (.D(n142), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_4));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i5.GSR = "ENABLED";
    FD1P3AX count_i0_i6 (.D(n141), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_5));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i6.GSR = "ENABLED";
    FD1P3AX count_i0_i7 (.D(n140), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_6));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i7.GSR = "ENABLED";
    FD1P3AX count_i0_i8 (.D(n139), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_7));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i8.GSR = "ENABLED";
    FD1P3AX count_i0_i1 (.D(n146), .SP(sysclk_c_enable_8), .CK(sysclk_c), 
            .Q(count_c_0));   // ../src/fpga_uart_top.v(20[10] 38[8])
    defparam count_i0_i1.GSR = "ENABLED";
    LUT4 equal_32_i6_2_lut (.A(id_c), .B(updwn_c), .Z(n6)) /* synthesis lut_function=(A+(B)) */ ;
    defparam equal_32_i6_2_lut.init = 16'heeee;
    LUT4 i155_2_lut (.A(data_c_4), .B(reset_c), .Z(n115)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i155_2_lut.init = 16'hbbbb;
    LUT4 i156_2_lut (.A(data_c_5), .B(reset_c), .Z(n114)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i156_2_lut.init = 16'hbbbb;
    LUT4 i153_2_lut (.A(data_c_2), .B(reset_c), .Z(n117)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i153_2_lut.init = 16'hbbbb;
    LUT4 i151_2_lut (.A(data_c_0), .B(reset_c), .Z(n119)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i151_2_lut.init = 16'hbbbb;
    LUT4 i152_2_lut (.A(data_c_1), .B(reset_c), .Z(n118)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i152_2_lut.init = 16'hbbbb;
    PUR PUR_INST (.PUR(VCC_net));
    defparam PUR_INST.RST_PULSE = 1;
    LUT4 i55_1_lut (.A(updwn_c), .Z(n132)) /* synthesis lut_function=(!(A)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i55_1_lut.init = 16'h5555;
    LUT4 i157_2_lut (.A(data_c_6), .B(reset_c), .Z(n113)) /* synthesis lut_function=(A+!(B)) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i157_2_lut.init = 16'hbbbb;
    LUT4 i1_4_lut (.A(id_c), .B(reset_c), .C(action_c), .D(updwn_c), 
         .Z(sysclk_c_enable_8)) /* synthesis lut_function=(!(A (B+(C+(D)))+!A (B (C+(D))+!B (C (D)+!C !(D))))) */ ;   // ../src/fpga_uart_top.v(21[7] 37[14])
    defparam i1_4_lut.init = 16'h0116;
    
endmodule
//
// Verilog Description of module TSALL
// module not written out since it is a black-box. 
//

//
// Verilog Description of module PUR
// module not written out since it is a black-box. 
//

