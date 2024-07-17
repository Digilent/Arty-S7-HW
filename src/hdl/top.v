`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Arthur Brown
// 
// Create Date: 06/06/2024 12:42:27 PM
// Design Name: Clocking Wizard Testbed
// Module Name: top
// Target Devices: Arty S7
// Tool Versions: 2023.1
// Description: Bridges a UART interface to the Clocking Wizard AXI registers, driving output registers with variable clocks,
//              to explore what effect different clocking wizard settings have.
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top #(
    parameter integer baud_counter_max = 10416,
    parameter integer debounce_period = 10
) (
    // 100 MHz clock input
    input  wire       clk,
    // asynchronous reset input, minimum duration 160 ns (16x 100 MHz clocks) from PG085's section on resets.
    // physical reset button could be bouncy, if this causes issues, a processor system reset could be used to guarantee 16 clock cycles
    input  wire       resetn, 
    
    output wire [7:0] pmod_ja,
    output wire [7:0] pmod_jb,
    output wire [7:0] pmod_jc,
    input  wire       pmod_jd_0,
    output wire       pmod_jd_1,
    input  wire       uart_rx_in,
    output wire       uart_tx_out,
    input  wire       sw0,
    output wire       led0,
    output wire       led1
);
    wire base_sync_resetn; // Synchronous deassert asynchronous assert reset
    
    // ==== Reset Synchronizer ====
    // Note: relies on false path constraints in timing.xdc. If xpm_cdc_async_rst was used instead, these constraints might be unnecessary
    ResetBridge #(
        .kPolarity (0),
        .kStages   (2),
        .kOutputFF (0)
    ) base_sync_inst (
        .aRst   (resetn),
        .OutClk (clk),
        .aoRst  (base_sync_resetn)
    );
   
    // ==== RX Multiplexor ====
    wire uart_rx_bouncy;
    assign uart_rx_bouncy = (sw0) ? (uart_rx_in) : (pmod_jd_0);
    wire uart_rx;
    debouncer #(
        .period             (debounce_period),
        .data_initial_state (1'b1)
    ) debouncer_inst (
        .clk        (clk),
        .resetn     (base_sync_resetn),
        .data_in    (uart_rx_bouncy),
        .data_out   (uart_rx)
    );
    
    // ==== UART Receiver to AXI Stream ====
    wire uart_overflow_err;
    wire [7:0] uart_tdata;
    wire uart_tvalid;
    wire uart_tready;
    uart_receiver #(
        .baud_counter_max (baud_counter_max)
    ) uart_receiver_inst (
        .clk            (clk),
        .resetn         (base_sync_resetn),
        .uart_rx        (uart_rx),
        .m_axis_tdata   (uart_tdata),
        .m_axis_tvalid  (uart_tvalid),
        .m_axis_tready  (uart_tready),
        .overflow       (uart_overflow_err)
    );
    
    // ==== State Machine - Parallelizes incoming serial bytes and handles AXI master communication ====
    localparam integer STATE_AWAIT_COMMAND = 0;
    localparam integer STATE_WRITE_ADDR_AND_DATA = 1;
    localparam integer STATE_WRITE_ADDR = 2;
    localparam integer STATE_WRITE_DATA = 3;
    localparam integer STATE_READ_ADDR = 4;
    localparam integer STATE_READ_DATA = 5;
    localparam integer STATE_READ_FORWARD = 6;
    localparam integer STATE_AWAIT_BRESP = 7;
    localparam integer STATE_BITS = 3;
    localparam integer COMMAND_BYTES = 7;
    localparam [7:0] READ_OP = "r";
    localparam [7:0] WRITE_OP = "w";
    // command buffer could be replaced with another axi4-stream data width converter. all it does is parallelize seven serial bytes.
    reg [7:0] command [6:0];
    reg [STATE_BITS-1:0] state;
    reg [7:0] command_byte;
    wire awready;
    wire wready;
    wire arready;
    wire rvalid;
    wire bvalid;
    reg [1:0] bytes_sent = 0;
    
    always @(posedge clk, negedge base_sync_resetn) begin
        if (base_sync_resetn == 1'b0) begin
            state <= 0;
        end else begin
            case (state)
            // wait for the command buffer to fill, then initiate the corresponding AXI transaction
            STATE_AWAIT_COMMAND: begin
                if (uart_tvalid && command_byte + 1 == COMMAND_BYTES) begin
                    if (command[0] == WRITE_OP)     state <= STATE_WRITE_ADDR_AND_DATA;
                    else if (command[0] == READ_OP) state <= STATE_READ_ADDR;
                end
            end
            // note: write address and write data must be asserted at the same time to conform to AXI spec
            //       downstream controller can assert ready for both in any order, so we have to branch depending on 
            STATE_WRITE_ADDR_AND_DATA: begin
                if (awready && wready) state <= STATE_AWAIT_BRESP;
                else if (awready)      state <= STATE_WRITE_DATA;
                else if (wready)       state <= STATE_WRITE_ADDR;
            end
            STATE_WRITE_ADDR:   if (awready)                             state <= STATE_AWAIT_BRESP;
            STATE_WRITE_DATA:   if (wready)                              state <= STATE_AWAIT_BRESP;
            STATE_AWAIT_BRESP:  if (bvalid)                              state <= STATE_AWAIT_COMMAND;
            // note: read data does not require its own state since baud rates of input and output match and we
            //       always reply with less bytes than received, so the uart transmitter should always be ready
            //       thus we couple the read data stream directly to the uart transmitter input stream
            STATE_READ_ADDR:    if (arready)                             state <= STATE_AWAIT_COMMAND;
            default:                                                     state <= STATE_AWAIT_COMMAND;
            endcase
        end
    end
    
    assign uart_tready = (state == STATE_AWAIT_COMMAND);
    always @(posedge clk, negedge base_sync_resetn) begin: command_regs
        integer i;
        if (base_sync_resetn == 1'b0) begin
            for (i = 0; i < COMMAND_BYTES; i = i + 1) begin
                command[i] <= 'b0;
            end
            command_byte <= 'b0;
        end else begin
            if (state == STATE_AWAIT_COMMAND && uart_tvalid) begin
                command[command_byte] <= uart_tdata;
                if (command_byte + 1 == COMMAND_BYTES)
                    command_byte <= 'b0;
                else
                    command_byte <= command_byte + 1;
            end
        end
    end
    
    wire [31:0] rdata;
    wire [7:0] uart_tx_tdata;
    wire uart_tx_tready;
    wire uart_tx_tvalid;
    
    // ==== AXI Lite Master Signals ====
    wire [10:0] awaddr;
    wire [10:0] araddr;
    wire        awvalid;
    wire [31:0] wdata;
    wire [3:0]  wstrb;
    wire        wvalid;
    wire [1:0]  bresp;
    wire        bready;
    wire        arvalid;
    wire        rready;
    
    assign awaddr = {command[1][2:0], command[2]};
    assign araddr = {command[1][2:0], command[2]};
    assign wdata = {command[3], command[4], command[5], command[6]};
    assign bready =  (state == STATE_AWAIT_BRESP);
    assign awvalid = (state == STATE_WRITE_ADDR || state == STATE_WRITE_ADDR_AND_DATA);
    assign wvalid = (state == STATE_WRITE_DATA || state == STATE_WRITE_ADDR_AND_DATA);
    assign wstrb = 4'hf;
    assign arvalid = (state == STATE_READ_ADDR);
    
    // ==== Clocking Wizard ====
    wire [3:0] clk_out;
    wire locked;
    clk_wiz_0 clk_wiz_inst (
        .s_axi_aclk      (clk),
        .s_axi_aresetn   (base_sync_resetn),
        // AXI interface
        .s_axi_awaddr    (awaddr),
        .s_axi_awvalid   (awvalid),
        .s_axi_awready   (awready),
        .s_axi_wdata     (wdata),
        .s_axi_wstrb     (wstrb),
        .s_axi_wvalid    (wvalid),
        .s_axi_wready    (wready),
        .s_axi_bresp     (bresp),
        .s_axi_bvalid    (bvalid),
        .s_axi_bready    (bready),
        .s_axi_araddr    (araddr),
        .s_axi_arvalid   (arvalid),
        .s_axi_arready   (arready),
        .s_axi_rdata     (rdata),
        .s_axi_rresp     (),
        .s_axi_rvalid    (rvalid),
        .s_axi_rready    (rready),
        // Clock out ports
        .clk_out1        (clk_out[0]),
        .clk_out2        (clk_out[1]),
        .clk_out3        (clk_out[2]),
        .clk_out4        (clk_out[3]),
        // Status and control signals
        .locked          (locked),
       // Clock in ports
        .clk_in1         (clk)
        // Note: Option to enable IP "reset" signal is disabled when AXI interface is enabled, reset may be tied off or tied to axi reset
    );
    
    // ==== Read Data Serializer ====
    wire [31:0] rdata_MSB_first;
    assign rdata_MSB_first = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
    
    axis_dwidth_converter_0 word_to_byte_inst (
        .aclk           (clk),
        .aresetn        (base_sync_resetn),
        .s_axis_tvalid  (rvalid),
        .s_axis_tready  (rready),
        .s_axis_tdata   (rdata_MSB_first),
        .m_axis_tvalid  (uart_tx_tvalid),
        .m_axis_tready  (uart_tx_tready),
        .m_axis_tdata   (uart_tx_tdata)
    );
    
    // ==== UART Transmitter ====
    uart_transmitter #(
        .baud_counter_max (baud_counter_max)
    ) uart_transmitter_inst (
        .clk           (clk),
        .resetn        (base_sync_resetn),
        .s_axis_tdata  (uart_tx_tdata),
        .s_axis_tvalid (uart_tx_tvalid),
        .s_axis_tready (uart_tx_tready),
        .uart_tx       (uart_tx_out)
    );
    
    // ==== Output Buffers ====
    reg [3:0] output_reg = 'b0;
    wire [3:0] sync_resetn;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : output_buffers
            ResetBridge #(
                .kPolarity (0),
                .kStages   (2),
                .kOutputFF (0)
            ) sync_inst (
                // Note: The locked signal is or-ed into the reset so that the output registers are reset to a known
                //       state whenever the clocking wizard is reprogrammed. This also acts as a power-on reset,
                //       putting the outputs to 0 when the board is powered on regardless of the state of the reset
                //       button.
                .aRst   (resetn | locked),
                .OutClk (clk_out[i]),
                .aoRst  (sync_resetn[i])
            );
            always @(posedge clk_out[i], negedge sync_resetn[i]) begin
                if (sync_resetn[i] == 1'b0) begin
                    output_reg[i] <= 'b0;
                end else begin
                    output_reg[i] <= ~output_reg[i];
                end
            end
        end
    endgenerate
    assign {pmod_ja, pmod_jb, pmod_jc} = {6{output_reg}}; // connect all four outputs to both the top and bottom row of each pmod port
    
    // ==== Other Assorted Outputs ====
    assign led0 = uart_overflow_err;
    assign led1 = locked;
    assign pmod_jd_1 = uart_tx_out;
endmodule
