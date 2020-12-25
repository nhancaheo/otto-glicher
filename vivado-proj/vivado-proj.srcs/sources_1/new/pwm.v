`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2020 11:46:42 AM
// Design Name: 
// Module Name: pwm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pwm(
    input clk,
    input i_duty,
    output reg o_state
    );
    
    reg [7:0] counter = 0;

    always @ (posedge clk)
    begin
        counter <= counter + 1;
        o_state <= (counter < i_duty);
    end
endmodule
