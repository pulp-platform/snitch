ROOT_DIR							?= /scratch/msc22f9/mempool
SNITCH_DIR						?= /scratch/msc22f9/snitch
HW_DIR								?= /scratch/msc22f9/snitch/hw/system/snitch_cluster
INSTALL_PREFIX        ?= install
SOFTWARE_DIR          ?= ${SNITCH_DIR}/sw
INSTALL_DIR           ?= ${ROOT_DIR}/${INSTALL_PREFIX}
GCC_INSTALL_DIR       ?= ${INSTALL_DIR}/riscv-gcc
ISA_SIM_INSTALL_DIR   ?= ${INSTALL_DIR}/riscv-isa-sim
LLVM_INSTALL_DIR      ?= ${INSTALL_DIR}/llvm
HALIDE_INSTALL_DIR    ?= ${INSTALL_DIR}/halide
BENDER_INSTALL_DIR    ?= ${INSTALL_DIR}/bender
VERILATOR_INSTALL_DIR ?= ${INSTALL_DIR}/verilator
RISCV_TESTS_DIR       ?= ${SOFTWARE_DIR}/riscv-tests

test: build_test
	export PATH=$(ISA_SIM_INSTALL_DIR)/bin:$$PATH; \
	make -C $(RISCV_TESTS_DIR)/isa run \
  make -C $(SOFTWARE_DIR) test \
	make -C $(HW_DIR) bin/snitch_cluster.vsim \
	make -C $(HW_DIR) simc_test

build_test:
	cd $(RISCV_TESTS_DIR); \
	autoconf && ./configure --with-xlen=32 --prefix=$$(pwd)/target && \
	make isa -j4 && make install && \
	cd isa && make -j4 all

clean_test:
	$(MAKE) -C $(SOFTWARE_DIR) clean
	$(MAKE) -C $(RISCV_TESTS_DIR) clean
	$(MAKE) -C $(HW_DIR) clean_test
