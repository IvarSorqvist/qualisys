#!/bin/bash

# Analysis of the design
ghdl -a --ieee=synopsys -fexplicit noise_reduction.vhdl noise_reduction_tb.vhdl
# Elaborate
ghdl -e --ieee=synopsys -fexplicit noise_reduction_tb
# Run
ghdl -r --ieee=synopsys -fexplicit noise_reduction_tb --wave=noise_reduction_tb.ghw

