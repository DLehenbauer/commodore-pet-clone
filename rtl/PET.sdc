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
set clk_16 { pll|altpll_component|pll|clk[0] }

set pi_select  [get_registers { timing:timing|bus:bus|state[0] }]
set pi_strobe  [get_registers { timing:timing|bus:bus|state[1] }]
set cpu_select [get_registers { timing:timing|bus:bus|state[2] }]
set io_select  [get_registers { timing:timing|bus:bus|state[3] }]
set cpu_strobe [get_registers { timing:timing|bus:bus|state[4] }]

set pi_done [get_registers { timing:timing|sync:pi_sync|done }]
set phi2 [get_ports { phi2 }]

# Clock constraints
create_generated_clock -name "pi_select" \
    -source $clk_16 \
    -edges {1 7 33} \
    $pi_select

create_generated_clock -name "pi_strobe" \
    -source $clk_16 \
    -edges {3 5 35} \
    $pi_strobe

create_generated_clock -name "cpu_select" \
    -source $clk_16 \
    -edges {25 33 57} \
    $cpu_select

create_generated_clock -name "io_select" \
    -source $clk_16 \
    -edges {27 33 59} \
    $io_select

create_generated_clock -name "cpu_strobe" \
    -source $clk_16 \
    -edges {29 31 61} \
    $cpu_strobe

create_generated_clock -name "phi2" \
    -source $cpu_strobe \
    $phi2

# create_generated_clock -name "pi_done" \
#     -source $pi_select \
#     -invert \
#     $pi_done

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# CPU
# https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf (pg. 25)
    
# tBVD
set_input_delay -min -clock [get_clocks { phi2 }]  0 [get_ports { bus_addr[*] bus_rw_b }]
set_input_delay -max -clock [get_clocks { phi2 }] 30 [get_ports { bus_addr[*] bus_rw_b }]

# tMDS
set_input_delay -min -clock [get_clocks { phi2 }]  0 [get_ports { bus_data[*] }]
set_input_delay -max -clock [get_clocks { phi2 }] 40 [get_ports { bus_data[*] }]

# PIA/VIA
# https://www.westerndesigncenter.com/wdc/documentation/w65c21.pdf (pg. 8)

set_output_delay -min -clock { phi2 }  0 [get_ports { via_cs2_b pia2_cs2_b pia1_cs2_b }]
set_output_delay -max -clock { phi2 } -8 [get_ports { via_cs2_b pia2_cs2_b pia1_cs2_b }]

# SRAM
# https://www.alliancememory.com/wp-content/uploads/pdf/AS6C1008feb2007.pdf

set_output_delay -add_delay -min -clock { pi_select } 0 [get_ports { ram_ce_b ram_oe_b ram_we_b bus_addr[*] bus_data[*] }]
set_output_delay -add_delay -max -clock { pi_select } 7 [get_ports { ram_ce_b ram_oe_b ram_we_b bus_addr[*] bus_data[*] }]

set_output_delay -add_delay -min -clock { io_select } 0 [get_ports { ram_ce_b ram_oe_b ram_we_b }]
set_output_delay -add_delay -max -clock { io_select } 7 [get_ports { ram_ce_b ram_oe_b ram_we_b }]

# RPi

# set_output_delay -min -clock { pi_done } -7 [get_ports { pi_data[*] }]
# set_output_delay -max -clock { pi_done } -7 [get_ports { pi_data[*] }]