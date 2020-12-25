`timescale 1ns / 1ps

module testbench;

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
top uut (
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

reg tx_enable = 1'd0;
reg [7:0] tx_data = 8'd67;
wire tx_ready;
uart_tx tx1(
    .clk(sys_clk),
    .reset(reset),
    .data(tx_data),
    .enable(tx_enable),
    .tx(uart_txd_in),
    .ready(tx_ready)
);

// Main UART receiver
wire [7:0] rx_data;
wire rx_valid;
uart_rx rx1(
    .clk(sys_clk),
    .reset(reset),
    .data(rx_data),
    .rx(uart_rxd_out),
    .valid(rx_valid)
);

// Receiver for receiving uint32 via serial
reg u32_rec_enable = 1'd1;
wire u32_rec_valid;
wire [31:0] u32_rec_data;
uint32_receiver u32_rec(
    .clk(sys_clk),
    .reset(reset),
    .uart_data(rx_data),
    .uart_valid(rx_valid),
    .data(u32_rec_data),
    .data_valid(u32_rec_valid),
    .enable(u32_rec_enable)
);

reg trigger_enable;
reg [31:0] trigger_length;
wire [7:0] counter_out_wire;
reg trigger_reset = 1'b0;
wire [1:0] glitch_trigger_state;
wire [31:0] sleep_counter; 

trigger glitch_trigger(
    .clk(sys_clk),
    .reset(trigger_reset),
    .enable(trigger_enable),
    .in(trigger_in),
    .trigger_length(trigger_length),
    .triggered(glitch_trigger_triggered),
    .state(glitch_trigger_state),
    .counter_out(counter_out_wire),
    .sleep_counter(sleep_counter)
    );

initial 
begin
   sys_clk <= 1'b0;
   trigger_in <= 1'b1;
   gpio <= "A";
   reset <= 1'b0;
   trigger_length <= 32'd100;
end


// Generate 100MHz clock
always
begin
    #5 sys_clk <= ~sys_clk;
end

// Send one low bit per 2 cycles
always
begin
    #20 trigger_in <= ~trigger_in;
end

initial 
begin
    reset <= 1'b1;
    #10 reset <= 1'b0;
    trigger_enable <= 1'b1;
    #10 trigger_enable <= 1'b0; 
    tx_data <= 8'd70;
    tx_enable <= 1'b1;
    #10 tx_enable <= 1'b0;
    // 115200bd --> 0,1152 symbols / us
    // Wait roughly as long as it takes FPGA to send GPIO data to host before asking for flank counter
    #170000 tx_data <= 8'd50;
    #20 tx_enable <= 1'b1;
    #10 tx_enable <= 1'b0;
end
 
endmodule
