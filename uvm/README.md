# UVM testbench for topo.v

This folder contains a minimal, well-documented UVM testbench for the `topo` DUT.

Files:
- `tb_package.sv`: common package and typedefs
- `dut_if.sv`: virtual interface wrapped around DUT debug signals
- `dut_txn.sv`: transaction class (sequence item)
- `dut_sequencer.sv`, `dut_driver.sv`, `dut_monitor.sv`: agent components
- `dut_agent.sv`: agent wrapper
- `dut_predictor.sv`: reference model (placeholder)
- `dut_scoreboard.sv`: scoreboard comparing observed vs expected
- `dut_seq.sv`: example sequence(s)
- `dut_cov.sv`: functional coverage (basic placeholder)
- `dut_env.sv`: environment integrating all components
- `dut_test.sv`: main UVM test
- `tb_top.sv`: top-level testbench that instantiates DUT and starts UVM
- `run_xcelium.sh`: helper script to run with Xcelium (xrun)

Notes:
- This is a minimal, documented starting point. The predictor and coverage are placeholders
  and should be replaced/extended with a real golden model and detailed covergroups for
  real verification goals.
- To run with Xcelium, create a file list `files.f` listing RTL and TB sources (or adapt
  `run_xcelium.sh` to directly pass files). Example `files.f`:

  rtl/topo.v
  uvm/*.sv

Then run:

```bash
./uvm/run_xcelium.sh dut_test
```

If you prefer an open-source flow instead of Xcelium, consider using Verilator + cocotb;
I can generate a cocotb testbench that mirrors this UVM structure.
