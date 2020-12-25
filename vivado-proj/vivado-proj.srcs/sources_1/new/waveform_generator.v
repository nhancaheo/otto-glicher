`timescale 1ns / 1ps

module waveform_generator(
    input sys_clk,
    output [1:0] led,  // Led outputs
    output [2:0] rgb,  // RGB led
    input [1:0] btn, // buttons
    input [7:0] gpio, // GPIOs
    input uart_txd_in, // This is the RX input.. thanks for the naming digilent :D
    output uart_rxd_out, // This is the TX output
    
    input trigger_in,
    output power_out,
    output glitch_out
    );
    
// Used to reset all modules (not fully functional currently)
// TODO add debouncer for button
reg reset = 1'd0;
// Clock
wire main_clk;
// Generate a 100MHz clock from the external 12MHz clock
clk_wiz_0 clock_generator
(
.reset(reset),
// Clock out ports
.main_clk(main_clk),     // output main_clk
// Clock in ports
.clk_in1(sys_clk));      // input clk_in1

assign rgb = ~state[2:0];

// deal with fucking meta stability
reg uart_rxd_stable = 1'd0;
always @(posedge main_clk)
begin
    uart_rxd_stable <= uart_txd_in;
end


// Main UART transmitter
reg tx_enable_r = 1'd0;
reg [7:0] tx_data_r = 8'd67;
wire tx_ready;
uart_tx tx1(
    .clk(main_clk),
    .reset(reset),
    .data(tx_data_r),
    .enable(tx_enable_r),
    .tx(uart_rxd_out),
    .ready(tx_ready)
);

// Main UART receiver
wire [7:0] rx_data;
wire rx_valid;
uart_rx rx1(
    .clk(main_clk),
    .reset(reset),
    .data(rx_data),
    .rx(uart_rxd_stable),
    .valid(rx_valid)
);

// Transmitter for sending uint32 via serial
wire u32_uart_tx_enable;
reg u32_tx_enable = 1'b0;
reg [31:0] u32_tx_data = 1'b0;
wire u32_tx_ready;
wire [7:0] u32_uart_tx_data;
uint32_transmitter u32_tx(
    .clk(main_clk),
    .reset(reset),
    .u32_tx_enable(u32_tx_enable),
    .uart_ready(tx_ready),
    .data(u32_tx_data),
    .uart_data(u32_uart_tx_data),
    .uart_tx_enable(u32_uart_tx_enable),
    .ready(u32_tx_ready)
);

// Receiver for receiving uint32 via serial
reg u32_rec_enable = 1'd0;
wire u32_rec_valid;
wire [31:0] u32_rec_data;
uint32_receiver u32_rec(
    .clk(main_clk),
    .reset(reset),
    .uart_data(rx_data),
    .uart_valid(rx_valid),
    .data(u32_rec_data),
    .data_valid(u32_rec_valid),
    .enable(u32_rec_enable)
);


parameter STATE_WAIT_COMMAND = 8'd0;
parameter STATE_SET_PERIOD = 8'd1;
parameter STATE_SET_GLITCH_PULSE = 8'd2;

parameter CMD_SET_PERIOD = 8'd66;
parameter CMD_SET_GLITCH_PULSE = 8'd67;


reg [7:0] state = STATE_WAIT_COMMAND;

reg [31:0] period = 32'd100;
reg [31:0] pulse_length = 32'd50;
reg reset = 1'b0;

reg [31:0] timer = 32'd0;

reg enable = 1'b0;

assign glitch_out = enable;

always @(posedge main_clk)
begin
    u32_rec_enable <= 1'b0;
    state <= state;
    enable <= enable;
    timer <= timer + 1;   
    if(timer == period-1 && !enable)
    begin
        enable <= 1'b1;
        timer <= 1'b0;
    end
    if(timer == pulse_length-1 && enable)
    begin
        enable <= 1'b0;
        timer <= 1'b0;
    end        
    case(state)
        STATE_WAIT_COMMAND:
        begin
            if(rx_valid)
            begin
                case(rx_data)
                    CMD_SET_PERIOD:
                    begin
                        state <= STATE_SET_PERIOD;
                        u32_rec_enable <= 1'd1;
                    end
                    CMD_SET_GLITCH_PULSE:
                    begin
                        state <= STATE_SET_GLITCH_PULSE;
                        u32_rec_enable <= 1'd1;
                    end
                endcase
            end
        end
        STATE_SET_PERIOD:
        begin
            if(u32_rec_valid)
            begin
                period <= u32_rec_data;
                timer <= 1'b0;
                enable <= 1'b0;
                state <= STATE_WAIT_COMMAND;
            end
        end
        STATE_SET_GLITCH_PULSE:
        begin
            if(u32_rec_valid)
            begin
                pulse_length <= u32_rec_data;
                timer <= 1'b0;
                enable <= 1'b0;
                state <= STATE_WAIT_COMMAND;
            end
        end
    endcase                 
end


endmodule
