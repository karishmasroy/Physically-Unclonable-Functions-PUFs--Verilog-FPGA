# --- System Pins ---
set_property PACKAGE_PIN Y9 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
create_clock -period 10.000 -name clk_in [get_ports clk_in]

set_property PACKAGE_PIN P16 [get_ports cpu_reset]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_reset]

set_property PACKAGE_PIN Y11  [get_ports uart_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_txd]
set_property PACKAGE_PIN AA11 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd]

set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# --- 8-Column PUF Placement ---
# Rows R0-R7 placed in Columns X28-X35
for {set r 0} {$r < 8} {incr r} {
    for {set i 0} {$i < 64} {incr i} {
        set_property LOC SLICE_X[expr 28 + $r]Y[expr 50 + $i] [get_cells puf_inst/puf_rows[$r].puf_stages[$i].stage_inst]
    }
    # Arbiter placement
    set_property LOC SLICE_X[expr 28 + $r]Y115 [get_cells puf_inst/puf_rows[$r].puf_arbiter_inst]
}

set_false_path -from [get_ports cpu_reset]