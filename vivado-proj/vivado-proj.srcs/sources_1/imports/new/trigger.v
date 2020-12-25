`timescale 1ns / 1ps

module trigger(
    input clk,
    input reset,
    input enable,
    input in,
    input [31:0] trigger_length,
    input [31:0] edge_counter_max,
    input wire mode_selector,
    output reg triggered = 1'd0,
    output reg [2:0] state = 3'd0,
    output reg [31:0] counter_out = 8'd0
    );

parameter STATE_IDLE = 3'd0;
parameter STATE_WAIT_SLEEP = 3'd1;
parameter STATE_WAIT_LOW = 3'd2;
parameter STATE_TRIGGERING = 3'd3;
parameter STATE_WAIT_LOW_NO_PC = 3'd4;
parameter STATE_TRIGGERING_NO_PC = 3'd5;

reg [31:0] sleep_counter = 1'd0;
reg [31:0] edge_counter = 1'd0;

always @(posedge clk)
begin
    triggered <= 1'd0;
    sleep_counter <= sleep_counter;
    edge_counter <= edge_counter;
    state <= state;
    counter_out <= counter_out;
    
    if(reset)
    begin
        sleep_counter <= 1'd0;
        edge_counter <= 1'd0;
        counter_out <= 8'd0;
        state <= STATE_IDLE;
    end
    else
    begin
        case(state)
            STATE_IDLE:
            begin
                if(enable)
                begin
                    counter_out <= 8'd0;
                    sleep_counter <= 1'b0;
                    edge_counter <= 1'b0;
                    if(mode_selector)
                    begin
                        state <= STATE_WAIT_SLEEP;
                    end
                    else begin
                        state <= STATE_WAIT_LOW_NO_PC;
                    end
                end
            end
            // need extra sleep state since `enable` is only high for one cycle 
            STATE_WAIT_SLEEP:
            begin
                // wait 57_000 us, then start counting
                // clk is 100 MHz --> 1 cycle is 0,01 us
                // Need 57_000 / 0,01 == 5700_000 cycles  
                sleep_counter <= sleep_counter + 1;
               if(sleep_counter == 32'd5700_000)
                begin
                    sleep_counter <= 0;
                    state <= STATE_WAIT_LOW;
                end
            end
            STATE_WAIT_LOW:
            begin
                sleep_counter <= sleep_counter + 1;
                if(in == 1'b0)
                begin
                    edge_counter <= edge_counter + 1;
                end
                // magic value comes from measuring multiple time and calculating sensible lower bound
                // second value is necessary if nvtboot starts earlier than edge_counter_max
                if((edge_counter >= edge_counter_max) || (sleep_counter >= 32'd300_000))
//               if(sleep_counter == 32'd300_000)
                begin
                    counter_out <= edge_counter;
                    sleep_counter <= 0;
                    state <= STATE_TRIGGERING;
                end
            end
            STATE_TRIGGERING:
            begin
            // chip.fail people only trigger if there is a trigger input signal for x time here.
            // at this point we want to trigger in any case
                sleep_counter <= sleep_counter + 1;
                if(sleep_counter >= trigger_length)
                begin
                    triggered <= 1'd1;
                    state <= STATE_IDLE;
                    sleep_counter <= 1'b0;
                end
            end

            STATE_WAIT_LOW_NO_PC:
            begin
                if(in == 1'b0)
                begin
                    state <= STATE_TRIGGERING_NO_PC;
                end
            end
            STATE_TRIGGERING_NO_PC:
            begin
                if(in)
                begin
                    sleep_counter <= sleep_counter + 1;
                    if(sleep_counter >= trigger_length)
                    begin
                        triggered <= 1'd1;
                        state <= STATE_IDLE;
                    end
                end
                else
                begin
                    sleep_counter <= 0;
                end
            end

        endcase
        
    end
end

endmodule
