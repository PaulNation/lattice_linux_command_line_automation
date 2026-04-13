module LED_Driver (
    input wire [1:0] sw_connector,
    output wire [1:0] led_connector
);
    assign led_connector = sw_connector;

endmodule
