action = "simulation"
sim_tool = "modelsim"
sim_top = "sk6805_tb"

sim_post_cmd = "vsim -do ../vsim.do -c sk6805_tb"

modules = {
  "local" : [ "../../test/" ],
}
