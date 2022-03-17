# You must provide all the delay numbers
# CCLK delay is 0.5, 7.5 ns min/max T USRCCLKO  for Spartan-7 ; refer ds189-spartan-7-data-sheet.pdf
# Consider the max delay for worst case analysis
set cclk_delay 7.5

# Following are the SPI device parameters, taken from Spansion S25FL128S Data sheet 

# Max Tco
set tco_max 7
# Min Tco
set tco_min 1

# Setup time requirement
set tsu 3
# Hold time requirement
set th 2


# Following are the board/trace delay numbers
# Assumption is that all Data lines are matched
#4cm / 15cm/nanosec => 0.26 nanosec
set tdata_trace_delay_max 0.26
set tdata_trace_delay_min 0.2

set tclk_trace_delay_max 0.26
set tclk_trace_delay_min 0.2


### End of user provided delay numbers
# this is to ensure min routing delay from SCK generation to STARTUP input
# User should change this value based on the results
# having more delay on this net reduces the Fmax
set_max_delay 1.5 -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] -datapath_only

set_min_delay 0.1 -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO]


# Following command creates a divide by 2 clock
# It also takes into account the delay added by STARTUP block to route the CCLK
create_generated_clock  -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay]
# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK 
#falling edge


# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk
set_input_delay -clock clk_sck -max [expr $tco_max + $tdata_trace_delay_max + $tclk_trace_delay_max] [get_ports qspi_flash_io*_io] -clock_fall;
set_input_delay -clock clk_sck -min [expr $tco_min + $tdata_trace_delay_min + $tclk_trace_delay_min] [ get_ports qspi_flash_io*_io] -clock_fall;
set_multicycle_path 2 -setup -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 

set_multicycle_path 1 -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 
# Data is captured into SPI on the following rising edge of SCK
# Data is driven by the IP on alternate rising_edge of the ext_spi_clk
set_output_delay -clock clk_sck -max [expr $tsu + $tdata_trace_delay_max - $tclk_trace_delay_min] [get_ports qspi_flash_io*_io];
set_output_delay -clock clk_sck -min [expr $tdata_trace_delay_min -$th - $tclk_trace_delay_max] [get_ports qspi_flash_io*_io];
set_multicycle_path 2 -setup -start -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck 
set_multicycle_path 1 -hold -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck