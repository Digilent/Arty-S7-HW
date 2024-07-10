`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/11/2024 04:21:14 PM
// Design Name: 
// Module Name: debouncer
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


module debouncer #(
    parameter integer period = 100,
    parameter data_initial_state = 1'b0
) (
    input wire clk,
    input wire resetn,
    input wire data_in,
    output reg data_out
);
    reg [$clog2(period)-1:0] counter;
    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            counter <= 'b0;
        end else if (data_in != data_out) begin
            counter <= counter + 1;
        end else begin
            counter <= 'b0;
        end
    end
    always@(posedge clk) begin
        if (resetn == 1'b0) begin
            data_out <= data_initial_state;
        end else if (data_in != data_out && counter == period - 1) begin
            data_out <= data_in;
        end
    end
endmodule
