# Support for local override
BENDER		   ?= bender
DASM 	       ?= spike-dasm
VLT			   ?= verilator

VERILATOR_ROOT ?= $$(dirname $$(which $(VLT)))/../share/verilator
VLT_ROOT	   ?= ${VERILATOR_ROOT}

MATCH_END := '/+incdir+/ s/$$/\/*\/*/'
MATCH_BGN := 's/+incdir+//g'
SED_SRCS  := sed -e ${MATCH_END} -e ${MATCH_BGN}
TB_SRCS   := $(wildcard ${ROOT}/hw/ip/test/*.sv)
TB_DIR    := ${ROOT}/hw/ip/test/src

VSIM_BENDER   += -t test -t rtl -t simulation -t vsim
VSIM_SOURCES  := $(shell ${BENDER} script flist ${VSIM_BENDER} | ${SED_SRCS})
VSIM_BUILDDIR := work-vsim

# fesvr is being installed here
FESVR          ?= ${MKFILE_DIR}work
FESVR_VERSION  ?= 35d50bc40e59ea1d5566fbd3d9226023821b1bb6

VLT_BUILDDIR := work-vlt
VLT_FLAGS    += -Wno-BLKANDNBLK
VLT_FLAGS    += -Wno-LITENDIAN
VLT_FLAGS    += -Wno-CASEINCOMPLETE
VLT_FLAGS    += -Wno-CMPCONST
VLT_FLAGS    += -Wno-WIDTH
VLT_FLAGS    += -Wno-WIDTHCONCAT
VLT_FLAGS    += -Wno-UNSIGNED
VLT_FLAGS    += -Wno-UNOPTFLAT
VLT_FLAGS    += -Wno-fatal
VLT_FLAGS    += --unroll-count 1024
VLT_BENDER   += -t rtl
VLT_SOURCES  := $(shell ${BENDER} script flist ${VLT_BENDER} | ${SED_SRCS})
VLT_CFLAGS   ?= -std=c++14 -pthread -I ${VLT_BUILDDIR} -I $(VLT_ROOT)/include -I $(VLT_ROOT)/include/vltstd -I $(FESVR)/include -I $(TB_DIR)

#################
# Prerequisites #
#################
# Eventually it could be an option to package this statically using musl libc.
work/${FESVR_VERSION}_unzip:
	mkdir -p $(dir $@)
	wget -O $(dir $@)/${FESVR_VERSION} https://github.com/riscv/riscv-isa-sim/tarball/${FESVR_VERSION}
	tar xfm $(dir $@)${FESVR_VERSION} --strip-components=1 -C $(dir $@)
	touch $@

work/lib/libfesvr.a: work/${FESVR_VERSION}_unzip
	cd $(dir $<)/ && ./configure --prefix `pwd`
	make -C $(dir $<) install-config-hdrs install-hdrs libfesvr.a
	mkdir -p $(dir $@)
	cp $(dir $<)libfesvr.a $@

#############
# Verilator #
#############
# Takes the top module name as an argument.
define VERILATE
	mkdir -p $(dir $@)
	$(BENDER) script verilator ${VLT_BENDER} > $(dir $@)files
	$(VLT) \
		--Mdir $(dir $@) -f $(dir $@)files $(VLT_FLAGS) \
		-j $(shell nproc) --cc --build --top-module $(1)
	touch $@
endef

############
# Modelsim #
############

define QUESTASIM
	${VSIM} -c -do "source $<; quit" | tee $(dir $<)vsim.log
	@! grep -P "Errors: [1-9]*," $(dir $<)vsim.log
	@mkdir -p bin
	@echo "#!/bin/bash" > $@
	@echo '${VSIM} +permissive -work ${VSIM_BUILDDIR} -c \
				-ldflags "-Wl,-rpath,${FESVR}/lib -L${FESVR}/lib -lfesvr -lutil" \
				-t 1ps -voptargs=+acc $1 +permissive-off ++$$1 \
				-do "log -r /*; run -a"' >> $@
	@chmod +x $@
endef

#######
# VCS #
#######
work-vcs/compile.sh: ${VSIM_SOURCES} ${TB_SRCS}
	mkdir -p work-vcs
	${BENDER} script vcs ${VSIM_BENDER} --vlog-arg="-assert svaext -assert disable_cover -full64 -kdb" > $@
	chmod +x $@
	$@ > work-vcs/compile.log

########
# Util #
########
logs/trace_hart_%.txt: logs/trace_hart_%.dasm ${ROOT}/util/gen_trace.py
	$(DASM) < $< | $(PYTHON) ${ROOT}/util/gen_trace.py > $@

traces: $(shell (ls logs/trace_hart_*.dasm 2>/dev/null | sed 's/\.dasm/\.txt/') || echo "")
