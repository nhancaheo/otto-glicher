`timescale 1ns / 1ps


module u32_tx_tb;

reg sys_clk = 1'b0;
reg reset = 1'b1;

reg tx_enable_r = 1'd0;
wire tx_enable_w;
reg [7:0] tx_data_r = 8'd0;
wire [7:0] tx_data_w;
wire tx_ready;
wire uart_line;
uart_tx tx1(
    .clk(sys_clk),
    .reset(reset),
    .data(tx_data_w),
    .enable(tx_enable_w),
    .tx(uart_line),
    .ready(tx_ready)
);

// Main UART receiver
wire [7:0] rx_data;
wire rx_valid;
uart_rx rx1(
    .clk(sys_clk),
    .reset(reset),
    .data(rx_data),
    .rx(uart_line),
    .valid(rx_valid)
);

reg u32_rx_enable = 1'b0;
wire [31:0] u32_rx_data;
wire u32_rx_valid;
uint32_receiver u32_rx(
    .clk(sys_clk),
    .reset(reset),
    .enable(u32_rx_enable),
    .uart_data(rx_data),
    .uart_valid(rx_valid),
    .data(u32_rx_data),
    .data_valid(u32_rx_valid)
);

reg u32_tx_enable = 1'b0;
reg [31:0] u32_tx_data = 1'b0;
wire u32_tx_ready;
uint32_transmitter u32_tx(
    .clk(sys_clk),
    .reset(reset),
    .u32_tx_enable(u32_tx_enable),
    .uart_ready(tx_ready),
    .data(u32_tx_data),
    .uart_data(tx_data_w),
    .uart_tx_enable(tx_enable_w),
    .ready(u32_tx_ready)
);

// Generate 100MHz clock
always
begin
    #5 sys_clk <= ~sys_clk;
end

initial 
begin
    #20 reset <= 1'b0;
    u32_tx_data <= 32'h11223344;
    u32_tx_enable <= 1'b1;
    u32_rx_enable <= 1'b1;
    #10 u32_tx_enable <= 1'b0;
    #10 u32_rx_enable <= 1'b0;
//    tx_data_r <= 8'd42;
//    tx_enable_r <= 1'b1;
//    #10 tx_enable_r <= 1'b0;
end
 
endmodule