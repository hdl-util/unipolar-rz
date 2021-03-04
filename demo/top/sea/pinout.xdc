set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property IOSTANDARD LVCMOS33 [get_ports RGB]
set_property PACKAGE_PIN N11 [get_ports RGB]

set_property IOSTANDARD LVCMOS33 [get_ports RESET]
set_property PACKAGE_PIN D14 [get_ports RESET]

set_property IOSTANDARD LVCMOS33 [get_ports CLK_100MHZ]
set_property PACKAGE_PIN H4 [get_ports CLK_100MHZ]
create_clock -add -name CLK_100MHZ -period 10.00 -waveform {0 5} [get_ports CLK_100MHZ]
