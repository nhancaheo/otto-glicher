`timescale 1ns / 1ps

module test_waveform;

reg sys_clk;

reg trigger_in;

reg reset;

reg [1:0] btn;
reg [7:0] gpio;
wire uart_txd_in;
wire uart_rxd_out;
wire [1:0] led;
wire [2:0] rgb;
wire power_out;
wire glitch_out;
waveform_generator uut (
    .sys_clk(sys_clk),
    .led(led),
    .rgb(rgb),
    .btn(btn),
    .gpio(gpio),
    .uart_txd_in(uart_txd_in),
    .uart_rxd_out(uart_rxd_out),
    .trigger_in(trigger_in),
    .power_out(power_out),
    .glitch_out(glitch_out)
);

//reg tx_enable = 1'd0;
//reg [7:0] tx_data = 8'd0;
//wire tx_ready;
//uart_tx tx1(
//    .clk(sys_clk),
//    .reset(reset),
//    .data(tx_data),
//    .enable(tx_enable),
//    .tx(uart_txd_in),
//    .ready(tx_ready)
//);

//// Main UART receiver
//wire [7:0] rx_data;
//wire rx_valid;
//uart_rx rx1(
//    .clk(sys_clk),
//    .reset(reset),
//    .data(rx_data),
//    .rx(uart_rxd_out),
//    .valid(rx_valid)
//);

//// Receiver for receiving uint32 via serial
//reg u32_tx_enable = 1'd0;
//wire u32_tx_valid;
//wire uart_tx_enable;
//wire [7:0] u32_uart_tx_data;
//reg [31:0] u32_tx_data;
//uint32_transmitter u32_tx(
//    .clk(sys_clk),
//    .reset(reset),
//    .u32_tx_enable(u32_tx_enable),
//    .uart_ready(tx_ready),
//    .data(u32_tx_data),
//    .uart_data(u32_uart_tx_data),
//    .uart_tx_enable(uart_tx_enable),
//    .ready(ready)
//);

//reg trigger_enable;
//reg [31:0] trigger_length;
//wire [7:0] counter_out_wire;
//reg trigger_reset = 1'b0;
//wire [1:0] glitch_trigger_state;
//wire [31:0] sleep_counter; 

reg host_tx = 1'b1;
assign uart_txd_in = host_tx;

initial 
begin
   sys_clk <= 1'b0;
   reset <= 1'b0;
end


// Generate 100MHz clock
always
begin
    #5 sys_clk <= ~sys_clk;
end

//always
//begin
//    tx_enable <= uart_tx_enable;
//    tx_data <= u32_uart_tx_data;
//end



initial 
begin
    reset <= 1'b1;
    #10 reset <= 1'b0;
end
 
endmodule
