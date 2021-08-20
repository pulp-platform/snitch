# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nils Wistoff <nwistoff@iis.ee.ethz.ch>
#
# Add occamy signals to debug here

# Ariane commited PC
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/pc_commit[*]}]

# Ariane fetched instruction
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/i_frontend/icache_data_q[*]}]

# Ariane exception CSRs
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/csr_regfile_i/mcause_q[*]}]
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/csr_regfile_i/mtval_q[*]}]
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/csr_regfile_i/mepc_q[*]}]

# Boot ROM response
set_property MARK_DEBUG true [get_nets {bootrom_req_ready_q}]

# Ariane AXI
set_property MARK_DEBUG true [get_nets {i_occamy/soc_narrow_xbar_in_req[1]*}]
set_property MARK_DEBUG true [get_nets {i_occamy/soc_narrow_xbar_in_rsp[1]*}]

# Ariane cache interfaces
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/icache_dreq_if_cache*}]
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/icache_dreq_cache_if*}]
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/dcache_req_ports_ex_cache*}]
set_property MARK_DEBUG true [get_nets {i_occamy/i_occamy_cva6/i_cva6/dcache_req_ports_cache_ex*}]
