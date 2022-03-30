# pre-defined extensions

# RV32IMA := opcodes-rv32i opcodes-rv32m opcodes-rv32a opcodes-system

# Xpulpimg
RV32XPULPIMG := opcodes-xpulpbr_CUSTOM opcodes-xpulpclip_CUSTOM opcodes-xpulpmacsi_CUSTOM opcodes-xpulpslet_CUSTOM opcodes-xpulpvect_CUSTOM opcodes-xpulpvectshufflepack_CUSTOM opcodes-xpulpminmax_CUSTOM opcodes-xpulphwloop_CUSTOM
RV32XPULPIMG += opcodes-xpulpbitop_CUSTOM
# XPULPIMG_OPCODES += opcodes-xpulpbitopsmall_CUSTOM #is a subset of opcodes-xpulpbitop_CUSTOM

# Snitch
SNITCH_OPCODES := opcodes-dma_CUSTOM opcodes-frep_CUSTOM opcodes-ssr_CUSTOM

# default configurations
MEMPOOL_ISA := opcodes-frep_CUSTOM $(RV32XPULPIMG) opcodes-rv32d-zfh_DRAFT opcodes-rv32q-zfh_DRAFT opcodes-rv32zfh_DRAFT opcodes-rv64zfh_DRAFT opcodes-sflt_CUSTOM
SNITCH_ISA := $(RV32XPULPIMG) $(SNITCH_OPCODES) opcodes-sflt_CUSTOM
