`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Arthur Brown
// 
// Create Date: 06/11/2024 04:21:14 PM
// Design Name: Clocking Wizard Testbed
// Module Name: debouncer
// Target Devices: Arty S7
// Tool Versions: 2023.1
// Description: Simple debouncer. Prevents change in signal passing through until a new state has been constant for a specified number of cycles.
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module debouncer #(
    parameter integer period = 100,
    parameter data_initial_state = 1'b0
) (
    input wire clk,
    input wire resetn, // reset is active low asynchronously asserted and synchronously deasserted (in 'clk' domain)
    input wire data_in,
    output reg data_out
);
    reg [$clog2(period)-1:0] counter;
    always @(posedge clk, negedge resetn) begin
        if (resetn == 1'b0) begin
            counter <= 'b0;
        end else if (data_in != data_out) begin
            counter <= counter + 1;
        end else begin
            counter <= 'b0;
        end
    end
    always@(posedge clk, negedge resetn) begin
        if (resetn == 1'b0) begin
            data_out <= data_initial_state;
        end else if (data_in != data_out && counter == period - 1) begin
            data_out <= data_in;
        end
    end
endmodule
