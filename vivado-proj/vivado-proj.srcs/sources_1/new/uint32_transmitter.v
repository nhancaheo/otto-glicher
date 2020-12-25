`timescale 1ns / 1ps
`include "uart_definitions.v"

module uint32_transmitter(
    input wire clk,
    input wire reset,
    input wire u32_tx_enable,
    input wire uart_ready,
    
    // UART data
    input wire [31:0] data,
    
    // The UART transmitter data reg
    output wire [7:0] uart_data,
    output reg uart_tx_enable,
    // Whether the transmitter is currently busy or not
    output reg ready = 1'b1
    );

parameter STATE_IDLE = 3'd0;
parameter STATE_SENDING = 3'd1;
parameter STATE_WAITING = 3'd2;

reg [1:0] state = STATE_IDLE;
reg [3:0] sent_bytes = 4'd0;
reg [31:0] data_local = 1'b0;
reg [31:0] etu_counter = 32'd0;

assign uart_data = data_local[31:24];

always @(posedge clk)
begin
    // default assignments
    sent_bytes <= sent_bytes;
    state <= state;
    ready <= ready;
    data_local <= data_local;
    uart_tx_enable <= 1'b0;
    etu_counter <= etu_counter;
    if(reset)
    begin
        sent_bytes <= 4'd0;
        ready <= 1'b1;
        data_local <= 1'b0;
        etu_counter <= 1'b0;
        state <= STATE_IDLE;
    end
    else
    begin
        case(state)
            STATE_IDLE:
            begin
                if(u32_tx_enable)
                begin
                    data_local <= data;
                    sent_bytes <= 4'd0;
                    ready <= 1'b0;
                    state <= STATE_SENDING;
                end
            end
            STATE_SENDING:
            begin
                if(uart_ready)
                begin
                    uart_tx_enable <= 1'b1;
                    sent_bytes <= sent_bytes + 1;
                    if(sent_bytes == 3)
                    begin
                        state <= STATE_IDLE;
                        ready <= 1'b1;
                    end
                    else
                    begin
                        state <= STATE_WAITING;
                    end
                end
            end
            // this extra step is necessary since TX's ready bit is set to low only one cycle after setting tx_enable to high
            STATE_WAITING:
            begin
                etu_counter <= etu_counter + 1'd1;
                if(etu_counter >= `UART_HALF_ETU && uart_ready)
                begin
                    etu_counter <= 1'b0;
                    data_local <= {data_local[23:0], data_local[31:24]};
                    state <= STATE_SENDING;
                end                
            end
        endcase        
    end
end

endmodule
