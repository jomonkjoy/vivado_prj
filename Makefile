###############################################################################
# Vivado Non-Project Flow Makefile (Self-contained with filelist parser)
# Author: Jomon K Joy
###############################################################################

#------------------------------------------------------------------------------
# Vivado Environment Setup (fallback if not already set)
#------------------------------------------------------------------------------
ifndef VIVADO_HOME
  export VIVADO_HOME := /tools/Xilinx/Vivado
endif

ifndef VIVADO_VER
  export VIVADO_VER := 2019.2
endif

ifndef VIVADO_TOOL
  export VIVADO_TOOL := $(VIVADO_HOME)/$(VIVADO_VER)/bin
endif

export PATH := $(VIVADO_TOOL):$(PATH)

#------------------------------------------------------------------------------
# Project Configuration
#------------------------------------------------------------------------------
TOP_MODULE     := flit_pipeline
PART           := xc7k70tfbg484-2
FILELIST       := filelist.f
BUILD_DIR      := build
LOG_DIR        := $(BUILD_DIR)/logs
REPORT_DIR     := $(BUILD_DIR)/reports
PARSED_TCL     := $(BUILD_DIR)/files_read.tcl

VIVADO         := vivado
VIVADO_FLAGS   := -mode batch -nojournal -nolog

#------------------------------------------------------------------------------
# Default Target
#------------------------------------------------------------------------------
all: bit

#------------------------------------------------------------------------------
# Step 1: Parse filelist.f → TCL read commands
#------------------------------------------------------------------------------
$(PARSED_TCL): $(FILELIST)
	@mkdir -p $(BUILD_DIR)
	@echo ">>> Generating TCL source loader from $(FILELIST)..."
	@echo "# Auto-generated from $(FILELIST)" > $(PARSED_TCL)
	@grep -v '^[[:space:]]*#' $(FILELIST) | grep -v '^[[:space:]]*$$' | while read line; do \
		case "$$line" in \
			*+incdir+*) \
				dir=$${line#+incdir+}; \
				echo "read_verilog -sv -include $$dir" >> $(PARSED_TCL);; \
			*.sv|*.v) \
				echo "read_verilog -sv $$line" >> $(PARSED_TCL);; \
			*.vhd|*.vhdl) \
				echo "read_vhdl $$line" >> $(PARSED_TCL);; \
			*.xdc) \
				echo "read_xdc $$line" >> $(PARSED_TCL);; \
			*.xci) \
				echo "read_ip $$line" >> $(PARSED_TCL);; \
			*.dcp) \
				echo "read_checkpoint $$line" >> $(PARSED_TCL);; \
			*.bd) \
				echo "read_bd $$line" >> $(PARSED_TCL);; \
			*) \
				echo "# Skipping unknown file: $$line" >> $(PARSED_TCL);; \
		esac \
	done
	@echo ">>> TCL filelist generated: $(PARSED_TCL)"

#------------------------------------------------------------------------------
# Step 2: TCL generators (synth/impl/bit)
#------------------------------------------------------------------------------

define TCL_SYNTH
set top_module  [lindex $$argv 0]
set device_part [lindex $$argv 1]
set src_tcl     [lindex $$argv 2]
set build_dir   [lindex $$argv 3]
puts "=== Running Synthesis for $$top_module ==="
source $$src_tcl
synth_design -top $$top_module -part $$device_part
write_checkpoint -force $$build_dir/$${top_module}_synth.dcp
report_utilization -file $$build_dir/logs/$${top_module}_synth_util.rpt
report_timing_summary -file $$build_dir/logs/$${top_module}_synth_timing.rpt
puts "=== Synthesis Complete ==="
endef
export TCL_SYNTH

define TCL_IMPL
set top_module [lindex $$argv 0]
set build_dir  [lindex $$argv 1]
puts "=== Running Implementation for $$top_module ==="
open_checkpoint $$build_dir/$${top_module}_synth.dcp
opt_design
place_design
route_design
write_checkpoint -force $$build_dir/$${top_module}_impl.dcp
report_utilization -file $$build_dir/logs/$${top_module}_impl_util.rpt
report_timing_summary -file $$build_dir/logs/$${top_module}_impl_timing.rpt
puts "=== Implementation Complete ==="
endef
export TCL_IMPL

define TCL_BITGEN
set top_module [lindex $$argv 0]
set build_dir  [lindex $$argv 1]
puts "=== Running Bitstream Generation for $$top_module ==="
open_checkpoint $$build_dir/$${top_module}_impl.dcp
write_bitstream -force $$build_dir/$${top_module}.bit
report_timing_summary -file $$build_dir/logs/$${top_module}_bit_timing.rpt
puts "=== Bitstream Generation Complete ==="
endef
export TCL_BITGEN

#------------------------------------------------------------------------------
# Step 3: Flow targets
#------------------------------------------------------------------------------
syn: $(BUILD_DIR)/synth_done

$(BUILD_DIR)/synth_done: $(PARSED_TCL)
	@mkdir -p $(BUILD_DIR) $(LOG_DIR) $(REPORT_DIR)
	@echo "$$TCL_SYNTH" > $(BUILD_DIR)/synth.tcl
	@echo ">>> Running synthesis..."
	$(VIVADO) $(VIVADO_FLAGS) -source $(BUILD_DIR)/synth.tcl -tclargs $(TOP_MODULE) $(PART) $(PARSED_TCL) $(BUILD_DIR) | tee $(LOG_DIR)/synth.log
	@touch $@
	@echo ">>> Synthesis complete."

par: $(BUILD_DIR)/impl_done

$(BUILD_DIR)/impl_done: $(BUILD_DIR)/synth_done
	@echo "$$TCL_IMPL" > $(BUILD_DIR)/impl.tcl
	@echo ">>> Running implementation..."
	$(VIVADO) $(VIVADO_FLAGS) -source $(BUILD_DIR)/impl.tcl -tclargs $(TOP_MODULE) $(BUILD_DIR) | tee $(LOG_DIR)/impl.log
	@touch $@
	@echo ">>> Implementation complete."

bit: $(BUILD_DIR)/bit_done

$(BUILD_DIR)/bit_done: $(BUILD_DIR)/impl_done
	@echo "$$TCL_BITGEN" > $(BUILD_DIR)/bitgen.tcl
	@echo ">>> Running bitstream generation..."
	$(VIVADO) $(VIVADO_FLAGS) -source $(BUILD_DIR)/bitgen.tcl -tclargs $(TOP_MODULE) $(BUILD_DIR) | tee $(LOG_DIR)/bitgen.log
	@touch $@
	@echo ">>> Bitstream generated: $(BUILD_DIR)/$(TOP_MODULE).bit"

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------
clean:
	rm -rf $(BUILD_DIR) *.jou *.log *.str *.zip *.cache *.hw
	@echo ">>> Cleaned build directory."

#------------------------------------------------------------------------------
# Phony Targets
#------------------------------------------------------------------------------
.PHONY: all syn par bit clean
