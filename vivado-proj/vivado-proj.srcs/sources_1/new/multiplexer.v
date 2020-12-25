`timescale 1ns / 1ps

module multiplexer( 
    input wire select,
    input wire [1:0] in,
    output wire out
);

assign out = in[select];

endmodule