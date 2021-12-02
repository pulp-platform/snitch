// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

// Description: PMA Checks for Snitch.
package snitch_pma_pkg;

  localparam int unsigned NrMaxRules = 4;

  typedef struct packed {
      logic [47:0] base; // base which needs to match
      logic [47:0] mask; // bit mask which bits to consider when matching the rule
  } rule_t;

  typedef struct packed {
    // PMAs
    // Non-idempotent regions
    int unsigned            NrNonIdempotentRegionRules; // Number of non-idempotent rules
    rule_t [NrMaxRules-1:0] NonIdempotentRegion;
    // Execute Regions
    int unsigned            NrExecuteRegionRules; // Number of regions which have execute property
    rule_t [NrMaxRules-1:0] ExecuteRegion;
    // Cached Regions
    int unsigned            NrCachedRegionRules; // Number of regions which have cached property
    rule_t [NrMaxRules-1:0] CachedRegion;
    // Atomicity Regions
    int unsigned            NrAMORegionRules; // Number of regions which have Atomic property
    rule_t [NrMaxRules-1:0] AMORegion;
  } snitch_pma_t;

  // Public interface
  function automatic logic range_check(logic[47:0] base, logic[47:0] mask, logic[47:0] address);
    return (address & mask) == (base & mask);
  endfunction : range_check

  function automatic logic is_inside_nonidempotent_regions (snitch_pma_t cfg, logic[47:0] address);
    logic [NrMaxRules-1:0] pass;
    pass = '0;
    for (int unsigned k = 0; k < cfg.NrNonIdempotentRegionRules; k++) begin
      pass[k] =
        range_check(cfg.NonIdempotentRegion[k].base, cfg.NonIdempotentRegion[k].mask, address);
    end
    return |pass;
  endfunction : is_inside_nonidempotent_regions

  function automatic logic is_inside_execute_regions (snitch_pma_t cfg, logic[47:0] address);
    // if we don't specify any region we assume everything is accessible
    logic [NrMaxRules-1:0] pass;
    pass = '0;
    for (int unsigned k = 0; k < cfg.NrExecuteRegionRules; k++) begin
      pass[k] = range_check(cfg.ExecuteRegion[k].base, cfg.ExecuteRegion[k].mask, address);
    end
    return |pass;
  endfunction : is_inside_execute_regions

  function automatic logic is_inside_cacheable_regions (snitch_pma_t cfg, logic[47:0] address);
    automatic logic [NrMaxRules-1:0] pass;
    pass = '0;
    for (int unsigned k = 0; k < cfg.NrCachedRegionRules; k++) begin
      pass[k] = range_check(cfg.CachedRegion[k].base, cfg.CachedRegion[k].mask, address);
    end
    return |pass;
  endfunction : is_inside_cacheable_regions
endpackage
