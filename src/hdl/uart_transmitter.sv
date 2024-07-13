`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Arthur Brown
// 
// Create Date: 06/14/2024 11:13:34 AM
// Design Name: Clocking Wizard Testbed
// Module Name: uart_transmitter
// Target Devices: Arty S7
// Tool Versions: 2023.1
// Description: UART transmitter with AXI4-stream interface
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_transmitter #(
    parameter integer baud_counter_max = 10416,
    parameter most_significant_bit_first = 0
) (
    input  logic       clk,
    input  logic       resetn, // reset is active low asynchronously asserted and synchronously deasserted (in 'clk' domain)
    input  logic [7:0] s_axis_tdata,
    input  logic       s_axis_tvalid,
    input  logic       s_axis_tready,
    output logic       uart_tx
);
    typedef enum {
        STATE_IDLE,
        STATE_BUSY
    } STATE_T;
    
    STATE_T state = STATE_IDLE;
    logic [10:0] shift_register;
    logic [3:0] bit_counter;
    logic frame_strobe;
    logic [31:0] baud_counter;
    logic bit_strobe;
    localparam integer bit_counter_max = 10;
    
    always_ff @(posedge clk, negedge resetn) begin
        if (resetn == 1'b0) begin
            state <= STATE_IDLE;
        end else begin
            case (state)
            STATE_IDLE: if (s_axis_tvalid == 1'b1)                      state <= STATE_BUSY;
            STATE_BUSY: if (frame_strobe == 1'b1 && bit_strobe == 1'b1) state <= STATE_IDLE;
            endcase    
        end
    end
    assign s_axis_tready = (state == STATE_IDLE);
    
    always_ff @(posedge clk, negedge resetn) begin
        if (resetn == 1'b0) begin
            shift_register <= 'b0;
        end else if (state == STATE_IDLE && s_axis_tvalid == 1'b1) begin
            if (most_significant_bit_first)
                shift_register <= {2'b11, s_axis_tdata[0:7], 1'b0}; // load data in reverse order
            else
                shift_register <= {2'b11, s_axis_tdata, 1'b0};
        end else if (state == STATE_BUSY && bit_strobe == 1'b1) begin
            shift_register <= {shift_register[10], shift_register[10:1]};
        end
    end
    
    always_comb begin
        if (state == STATE_BUSY) begin
            uart_tx = shift_register[0];
        end else begin
            uart_tx = 1'b1;
        end
    end
    
    always_ff @(posedge clk, negedge resetn) begin
        if (resetn == 1'b0) begin
            baud_counter <= 'b0;
        end else if (state == STATE_BUSY) begin
            if (bit_strobe == 1'b1) begin
                baud_counter <= 'b0;
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end else begin
            baud_counter <= 'b0;
        end
    end
    assign bit_strobe = (baud_counter == baud_counter_max);
    
    always_ff @(posedge clk, negedge resetn) begin
        if (resetn == 1'b0) begin
            bit_counter <= 'b0;
        end else if (state == STATE_BUSY) begin
            if (bit_strobe == 1'b1) begin
                if (frame_strobe == 1'b1) begin
                    bit_counter <= 'b0;
                end else begin
                    bit_counter <= bit_counter + 1;
                end
            end else begin
                bit_counter <= bit_counter;
            end
        end else begin
            bit_counter <= 'b0;
        end
    end
    assign frame_strobe = (bit_counter == bit_counter_max);
endmodule
