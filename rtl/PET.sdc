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

# Aliases
set clk_16           { pll|altpll_component|pll|clk[0] }
                                 
set clk_8p           [get_registers { main:main|timing2:timing2|clk_8_o }]
set clk_8n           [get_registers { main:main|timing2:timing2|clk_8n }]
set spi_en           [get_registers { main:main|timing2:timing2|enable[0] }]
set enable_1         [get_registers { main:main|timing2:timing2|enable[1] }]
set enable_2         [get_registers { main:main|timing2:timing2|enable[2] }]
set enable_3         [get_registers { main:main|timing2:timing2|enable[3] }]
set enable_4         [get_registers { main:main|timing2:timing2|enable[4] }]
set enable_5         [get_registers { main:main|timing2:timing2|enable[5] }]
set enable_6         [get_registers { main:main|timing2:timing2|enable[6] }]
set cpu_en           [get_registers { main:main|timing2:timing2|enable[7] }]

set clk_cpu  [get_ports { clk_cpu_o }]
set spi_sclk [get_ports { spi_sclk_i }]

# New clock constraints
create_generated_clock -name "clk_8n"   -source $clk_16 -edges {  4  6  8 } $clk_8n
create_generated_clock -name "spi_en"   -source $clk_8n -edges { 15 17 31 } $spi_en
create_generated_clock -name "enable_1" -source $clk_8n -edges {  1  3 17 } $enable_1
create_generated_clock -name "enable_2" -source $clk_8n -edges {  3  5 19 } $enable_2
create_generated_clock -name "enable_3" -source $clk_8n -edges {  5  7 21 } $enable_3
create_generated_clock -name "enable_4" -source $clk_8n -edges {  7  9 23 } $enable_4
create_generated_clock -name "enable_5" -source $clk_8n -edges {  9 11 25 } $enable_5
create_generated_clock -name "enable_6" -source $clk_8n -edges { 11 13 27 } $enable_6
create_generated_clock -name "cpu_en"   -source $clk_8n -edges { 13 15 29 } $cpu_en

create_generated_clock -name "clk_8p"   -source $clk_16 -edges {  1  3  5 } $clk_8p
create_generated_clock -name "clk_cpu"  -source $clk_8p -edges { 15 16 31 } $clk_cpu

create_clock -name "spi_sclk" -period 8MHz $spi_sclk

# Old clock constraints
set cpu_select       [get_registers { main:main|timing:timing|bus:bus|state[5] }]
set cpu_strobe       [get_registers { main:main|timing:timing|bus:bus|state[7] }]

create_generated_clock -name "cpu_select" \
    -source $clk_16 \
    -edges {25 33 57} \
    $cpu_select

create_generated_clock -name "cpu_strobe" \
    -source $clk_16 \
    -edges {29 31 61} \
    $cpu_strobe
    
# create_generated_clock -name "pi_done" \
#     -source $pi_select \
#     -invert \
#     $pi_done

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# CPU
# https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf (pg. 25)
    
# tBVD
set_input_delay -min -clock [get_clocks { clk_cpu }]  0 [get_ports { bus_addr_io[*] bus_rw_nio }]
set_input_delay -max -clock [get_clocks { clk_cpu }] 30 [get_ports { bus_addr_io[*] bus_rw_nio }]

# tMDS
set_input_delay -min -clock [get_clocks { clk_cpu }]  0 [get_ports { bus_data_io[*] }]
set_input_delay -max -clock [get_clocks { clk_cpu }] 40 [get_ports { bus_data_io[*] }]

# PIA/VIA
# https://www.westerndesigncenter.com/wdc/documentation/w65c21.pdf (pg. 8)

set_output_delay -min -clock { clk_cpu }  0 [get_ports { via_cs2_no pia2_cs2_no pia1_cs2_no }]
set_output_delay -max -clock { clk_cpu } -8 [get_ports { via_cs2_no pia2_cs2_no pia1_cs2_no }]

# SRAM
# https://www.alliancememory.com/wp-content/uploads/pdf/AS6C1008feb2007.pdf

set_output_delay -add_delay -min -clock { spi_en } 0 [get_ports { ram_ce_no ram_oe_no ram_we_no bus_addr_io[*] ram_addr_o[*] bus_data_io[*] }]
set_output_delay -add_delay -max -clock { spi_en } 7 [get_ports { ram_ce_no ram_oe_no ram_we_no bus_addr_io[*] ram_addr_o[*] bus_data_io[*] }]

set_output_delay -add_delay -min -clock { cpu_en } 0 [get_ports { ram_ce_no ram_oe_no ram_we_no ram_addr_o[*] }]
set_output_delay -add_delay -max -clock { cpu_en } 7 [get_ports { ram_ce_no ram_oe_no ram_we_no ram_addr_o[*] }]

# RPi

# set_output_delay -min -clock { pi_done } -7 [get_ports { pi_data[*] }]
# set_output_delay -max -clock { pi_done } -7 [get_ports { pi_data[*] }]