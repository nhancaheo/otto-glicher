# Chip.Fail

Please visit our [website](https://chip.fail/) for details and bare with us while we get our documentation under way.

# Adapting Verilog Project

1. Create new Vivado Project
2. Setup board files for your target if available
3. Import `/sources_1/new` and the apropriate contraint file for your board.
4. Run clocking wizard to add new clock module, rename one 100 MHz output to `main_clk`
5. Connect target to your Host, open `Hardware Manager` in Vivado and check that Auto Connect recognized the correct device.
(Missing root permissions may hinder vivado to access the serial port)
5. Run Synthesis, Implementation, Bitstream Generation and finally programm your device

# Misc

- `chipfail-glitcher.py` is a simple copy of the jupyter notebook found at `jupyter/chipfail-glitcher.ipynb`. It may be used as an alternative by people who
  prefer not to use jupyter.