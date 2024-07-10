`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2024 01:01:49 PM
// Design Name: 
// Module Name: uart_receiver
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

module uart_receiver #(
    parameter integer baud_counter_max = 10416,
    parameter most_significant_bit_first = 0
) (
    input  wire       clk,
    input  wire       resetn,
    input  wire       uart_rx,
    output wire [7:0] m_axis_tdata,
    output wire       m_axis_tvalid,
    input  wire       m_axis_tready,
    output reg        overflow = 0
);
//    localparam integer baud_counter_max = 10416;
    localparam integer data_bits = 8;
    localparam integer stop_bits = 2;
    reg [31:0] baud_counter = 0;
    reg [7+stop_bits:0]  shift_register;
    reg [31:0] bit_counter;
    localparam integer STATE_AWAIT_START_BIT = 0;
    localparam integer STATE_WAIT_HALF_PERIOD = 1;
    localparam integer STATE_SAMPLING = 2;
    localparam integer STATE_FORWARD_TO_STREAM = 3;
    reg [1:0] state = 0;
    reg [7:0] output_register;
    
    always @(posedge clk) begin: state_machine_reg
        if (resetn == 1'b0) begin
            state <= 'b0;
        end else begin
            case (state)
            STATE_AWAIT_START_BIT:
                if (uart_rx == 1'b0) begin
                    state <= STATE_WAIT_HALF_PERIOD;
                end
            STATE_WAIT_HALF_PERIOD:
                if (baud_counter == baud_counter_max >> 1) begin
                    state <= STATE_SAMPLING;
                end
            STATE_SAMPLING:
                if (baud_counter == baud_counter_max && bit_counter == data_bits + stop_bits - 1) begin
                    state <= STATE_FORWARD_TO_STREAM;
                end
            STATE_FORWARD_TO_STREAM:
                if (m_axis_tready) begin
                    state <= STATE_AWAIT_START_BIT;
                end
            endcase
        end
    end
    
    always @(posedge clk) begin: baud_counter_reg
        if (resetn == 1'b0) begin
            baud_counter <= 'b0; 
        end else begin
            if (state == STATE_WAIT_HALF_PERIOD && baud_counter == baud_counter_max >> 1)
                baud_counter <= 'b0;
            else if (state == STATE_SAMPLING && baud_counter == baud_counter_max)
                baud_counter <= 'b0;
            else if (state == STATE_WAIT_HALF_PERIOD || state == STATE_SAMPLING)
                baud_counter <= baud_counter + 1;
            else
                baud_counter <= 'b0;
        end
    end
    
    always @(posedge clk) begin: bit_counter_reg
        if (resetn == 1'b0) begin
            bit_counter <= 'b0;
        end else if (state == STATE_SAMPLING) begin
            if (baud_counter == baud_counter_max) begin
                bit_counter <= bit_counter + 1;
            end else begin
                bit_counter <= bit_counter;
            end
        end else begin
            bit_counter <= 'b0;
        end
    end
    
    always @(posedge clk) begin: shift_reg
        if (resetn == 1'b0) begin
            shift_register <= 'b0;
        end else if (state == STATE_SAMPLING) begin
            if (baud_counter == baud_counter_max) begin
                if (most_significant_bit_first)
                    shift_register <= {shift_register[6+stop_bits:0], uart_rx};
                else
                    shift_register <= {uart_rx, shift_register[7+stop_bits:1]};
            end
        end else if (state != STATE_FORWARD_TO_STREAM) begin
            shift_register <= 'b0;
        end
    end
    
    always @(posedge clk) begin: overflow_error_reg
        if (resetn == 1'b0) begin
            overflow <= 1'b0;
        end else if (state == STATE_FORWARD_TO_STREAM && uart_rx == 1'b0) begin
            overflow <= 1'b1;
        end
    end
    
    assign m_axis_tvalid = (state == STATE_FORWARD_TO_STREAM);
    generate
        if (most_significant_bit_first)
            assign m_axis_tdata = shift_register[stop_bits+:8];
        else
            assign m_axis_tdata = shift_register[7:0];
        endgenerate
endmodule
