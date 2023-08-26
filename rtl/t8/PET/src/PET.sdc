# PET Clone - Open hardware implementation of the Commodore PET
# by Daniel Lehenbauer and contributors.
# 
# https://github.com/DLehenbauer/commodore-pet-clone
#
# To the extent possible under law, I, Daniel Lehenbauer, have waived all
# copyright and related or neighboring rights to this project. This work is
# published from the United States.
#
# @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
# @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors

# (See also generated file: outflow\PET.pt.sdc)

# Helpers
#########

# Calculate period in nanoseconds from frequency in megahertz.
proc ns_from_mhz { mhz } {
    set result [expr { 1000 / $mhz }]
    return $result
}

# PLL Constraints
#################
create_clock -period [ns_from_mhz 16] clk16_i
create_clock -period [ns_from_mhz 160] clk_sys_i

# SPI1 Constraints
##################

# SPI mode 0 (CPOL=0, CPHA=0) is a center-aligned source synchronous SDR interface.
# Clock is low when idle.  Data is sampled on rising edge and shifted out on falling edge.
#
#       CS_N  ‾‾‾\_______________________________________________________________________/‾‾‾
#              . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : .  
#        SCK  ___________/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\_______
#              . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : .  
#         TX  -------<​_​̅_​̅_​̅7​̅_​̅_​̅_X_​̅_​̅_​̅6​̅_​̅_​̅_X_​̅_​̅_​̅5​̅_​̅_​̅_X_​̅_​̅_​̅4​̅_​̅_​̅_X_​̅_​̅_​̅3​̅_​̅_​̅_X_​̅_​̅_​̅2​̅_​̅_​̅_X_​̅_​̅_​̅1​̅_​̅_​̅_X_​̅_​̅_​̅0​̅_​̅_​̅_>-------
#              . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . 
#         RX  ----<​_​̅_​̅_​̅_​̅_​̅_​̅7​̅_​̅_​̅_X_​̅_​̅_​̅6​̅_​̅_​̅_X_​̅_​̅_​̅5​̅_​̅_​̅_X_​̅_​̅_​̅4​̅_​̅_​̅_X_​̅_​̅_​̅3​̅_​̅_​̅_X_​̅_​̅_​̅2​̅_​̅_​̅_X_​̅_​̅_​̅1​̅_​̅_​̅_X_​̅_​̅_​̅0​̅_​̅_​̅_​̅_​̅_​̅_​̅_>---
#              . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : . : .  
#    READY_N  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\____/‾‾‾

# (See https://www.intel.com/content/dam/altera-www/global/en_US/pdfs/literature/an/an433.pdf)

set spi1_sck_period_mhz 16
set spi1_sck_period_ns [ns_from_mhz $spi1_sck_period_mhz]

# 'spi1_sck_v' is a virtual clock that models the edges at which TX and RX transition
create_clock -name spi1_sck_v -period $spi1_sck_period_ns

# 'spi1_sck_i' is the incoming SCK used to sample TX/RX between transitions.  Note that
# SCK is center-aligned (phase-shifted 90 degrees from 'spi1_sck_v'.)
create_clock -name "spi1_sck_i" -period $spi1_sck_period_ns -waveform [list [expr { $spi1_sck_period_ns * 0.25 }] [expr { $spi1_sck_period_ns * 0.75 }]] [get_ports spi1_sck_i]

# SPI sampling and data clocks are asynchronous/unrelated to other clocks in the design.
set_clock_groups -asynchronous -group {spi1_sck_v spi1_sck_i}

# Remember: TX is incoming from the MCU (RX for the FPGA)

# Assume TX transitions within +/- 250ps of virtual data clock edge
set_input_delay -max -clock spi1_sck_v 0.250 [get_ports {spi1_mcu_tx_i}]
set_input_delay -min -clock spi1_sck_v -0.250 [get_ports {spi1_mcu_tx_i}]

# Remember: RX is outgoing to the MCU (TX for the FPGA)

# Assume the required RX data valid window is 1/2 the SCK period, centered on the sampling edge.
set_output_delay -clock spi1_sck_i -max [expr { $spi1_sck_period_ns * 0.25 }] [get_ports {spi1_mcu_rx_o}]
set_output_delay -clock spi1_sck_i -min [expr { $spi1_sck_period_ns * -0.25 }] [get_ports {spi1_mcu_rx_o}]

# Assume CS_N transitions within +/- 250ps of sampling clock.
#
# Under hardware control CS_N asserts on what would be the rising SCK edge prior the first bit
# and deasserts on the rising SCK edge after the last bit (if SCK weren't disabled).
#
# Under software control, CS_N is unsynchronized, but generally delayed more than a clock period
# at 4 MHz or above.
set_input_delay -clock spi1_sck_i -max [expr { $spi1_sck_period_ns * 0.25 }] [get_ports {spi1_cs_ni}]
set_input_delay -clock spi1_sck_i -min [expr { $spi1_sck_period_ns * -0.25 }] [get_ports {spi1_cs_ni}]

# Assume that FPGA begins driving the TX (FPGA) -> RX (MCU) pin within 50ns of /CS_N being asserted.
# To constrain this combinatorial logic, we model CS_N as an asynchronous clock.
create_clock -name "spi1_cs_n" -period 50 [get_ports spi1_cs_ni]
set_clock_groups -asynchronous -group {spi_cs_n}

set_output_delay -clock spi1_cs_n -max [expr { $spi1_sck_period_ns * 0.25 }] [get_ports {spi1_mcu_rx_oe}]
set_output_delay -clock spi1_cs_n -min [expr { $spi1_sck_period_ns * -0.25 }] [get_ports {spi1_mcu_rx_oe}]

# GPIO Constraints
####################
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {clk_50_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {clk_50_i}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_16_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_16_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_clk_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_clk_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {h_sync_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {h_sync_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {io_oe_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {io_oe_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {pia1_cs2_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {pia1_cs2_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {pia2_cs2_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {pia2_cs2_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {ram_addr_o[10]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {ram_addr_o[10]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {ram_addr_o[11]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {ram_addr_o[11]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {spi_ready_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {spi_ready_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {status_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {status_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {v_sync_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {v_sync_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {via_cs2_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {via_cs2_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {video_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {video_o}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[4]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[4]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[4]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[4]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[4]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[4]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[5]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[5]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[5]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[5]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[5]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[5]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[6]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[6]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[6]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[6]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[6]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[6]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[7]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[7]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[7]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[7]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[7]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[7]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[8]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[8]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[8]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[8]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[8]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[8]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[9]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[9]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[9]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[9]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[9]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[9]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[10]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[10]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[10]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[10]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[10]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[10]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[11]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[11]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[11]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[11]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[11]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[11]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[0]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[0]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[1]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[1]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[2]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[2]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[3]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[3]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[4]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[4]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[4]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[4]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[4]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[4]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[5]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[5]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[5]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[5]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[5]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[5]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[6]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[6]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[6]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[6]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[6]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[6]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_i[7]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_i[7]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_o[7]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_o[7]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_data_7_0_oe[7]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_data_7_0_oe[7]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_rw_ni}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_rw_ni}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_rw_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_rw_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_rw_noe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_rw_noe}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_res_nai}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_res_nai}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_res_nao}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_res_nao}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_res_naoe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_res_naoe}]

# LVDS RX GPIO Constraints
############################
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_be_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_be_o}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[0]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[0]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[0]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[0]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[1]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[1]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[1]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[1]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[2]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[2]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[2]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[2]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[3]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[3]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[3]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[3]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[12]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[12]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[12]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[12]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[12]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[12]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[13]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[13]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[13]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[13]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[13]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[13]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[14]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[14]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[14]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[14]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[14]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[14]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_i[15]}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_i[15]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_o[15]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_o[15]}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {bus_addr_15_0_oe[15]}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {bus_addr_15_0_oe[15]}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_irq_ni}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_irq_ni}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_irq_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_irq_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_irq_noe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_irq_noe}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_nmi_ni}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_nmi_ni}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_nmi_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_nmi_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_nmi_noe}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_nmi_noe}]

# LVDS Rx Constraints
####################

# LVDS TX GPIO Constraints
############################
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {diag_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {diag_i}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {gfx_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {gfx_i}]
# set_input_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {via_cb2_i}]
# set_input_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {via_cb2_i}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {audio_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {audio_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {cpu_ready_o}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {cpu_ready_o}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {ram_ce_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {ram_ce_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {ram_oe_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {ram_oe_no}]
# set_output_delay -clock <CLOCK> -max <MAX CALCULATION> [get_ports {ram_we_no}]
# set_output_delay -clock <CLOCK> -min <MIN CALCULATION> [get_ports {ram_we_no}]

# LVDS Tx Constraints
####################
