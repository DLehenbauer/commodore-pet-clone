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
set clk_8 [get_registers { timing:timing|count[0] }]
set clk_4 [get_registers { timing:timing|count[1] }]
set clk_2 [get_registers { timing:timing|count[2] }]
set clk_1 [get_registers { timing:timing|count[3] }]
set phi2 [get_ports { phi2 }]

# Clock constraints
create_generated_clock -name "clk_8" \
    -source $clk_16 \
    -divide_by 2 \
    $clk_8
    
create_generated_clock -name "clk_4" \
    -source $clk_16 \
    -divide_by 4 \
    $clk_4
    
create_generated_clock -name "clk_2" \
    -source $clk_16 \
    -divide_by 8 \
    $clk_2
    
create_generated_clock -name "clk_1" \
    -source $clk_16 \
    -divide_by 16 \
    $clk_1
    
create_generated_clock -name "phi2" \
    -source $clk_1 \
    $phi2

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf (pg. 25)
    
# tBVD
set_input_delay -min -clock [get_clocks { phi2 }]  0 [get_ports { bus_addr[*] bus_rw_b }]
set_input_delay -max -clock [get_clocks { phi2 }] 30 [get_ports { bus_addr[*] bus_rw_b }]

# tMDS
set_input_delay -min -clock [get_clocks { phi2 }]  0 [get_ports { bus_data[*] }]
set_input_delay -max -clock [get_clocks { phi2 }] 40 [get_ports { bus_data[*] }]

# https://www.westerndesigncenter.com/wdc/documentation/w65c21.pdf (pg. 8)

set_output_delay -min -clock { phi2 } -8 [get_ports { via_cs2_b pia2_cs2_b pia1_cs2_b }]
set_output_delay -max -clock { phi2 } -8 [get_ports { via_cs2_b pia2_cs2_b pia1_cs2_b }]

# ???
set_false_path -from { timing:timing|sync:pi_sync|state.PENDING } -to { timing:timing|sync:pi_sync|state.DONE }
