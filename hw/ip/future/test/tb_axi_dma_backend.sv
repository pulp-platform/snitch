// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
//
// Thomas Benz <tbenz@ethz.ch>

// top level of the simulation for the AXI DMA backend

module tb_axi_dma_backend;

  fixture_axi_dma_backend fix ();
  initial begin

    fix.reset();
    fix.clear_memory();
    fix.reset_lfsr();

    // ultra short transfers
    for (int i = 0; i < 20000; i = i + 1) begin
      fix.oned_random_launch(4, 0);
      $display();
    end
    fix.oned_random_launch(4, 1);
    fix.compare_memories();

    // medium short transfers
    for (int i = 0; i < 20000; i = i + 1) begin
      fix.oned_random_launch(10, 0);
      $display();
    end
    fix.oned_random_launch(10, 1);
    fix.compare_memories();

    // // short transfers
    for (int i = 0; i < 25000; i = i + 1) begin
      fix.oned_random_launch(100, 0);
      $display();
    end
    fix.oned_random_launch(100, 1);
    fix.compare_memories();

    // // medium transfers
    for (int i = 0; i < 1000; i = i + 1) begin
      fix.oned_random_launch(1000, 0);
      $display();
    end
    fix.oned_random_launch(1000, 1);
    fix.compare_memories();

    // long transfers
    for (int i = 0; i < 250; i = i + 1) begin
      fix.oned_random_launch(10000, 0);
      $display();
    end
    fix.oned_random_launch(10000, 1);
    fix.compare_memories();

    // ultra long transfers
    for (int i = 0; i < 100; i = i + 1) begin
      fix.oned_random_launch(65000, 0);
      $display();
    end
    fix.oned_random_launch(65000, 1);
    fix.compare_memories();

    $display("\nDone :D (in %18.9f seconds", $time() / 1000000.0);
    $display("SUCCESS");
    $stop();
  end

endmodule
