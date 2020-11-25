// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

`timescale 1ns/1ns
module axi_dma_tb;

    fixture_oned_axi_dma fix ();
    initial begin

        fix.reset();
        fix.clear_memory();
        fix.reset_lfsr();

        // ultra short transfers
        for(int i = 0; i < 10000; i = i + 1) begin
            fix.oned_random_launch(4);
            fix.compare_memories();
        end

        // medium short transfers
        for(int i = 0; i < 5000; i = i + 1) begin
            fix.oned_random_launch(10);
            fix.compare_memories();
        end

        // short transfers
        for(int i = 0; i < 1000; i = i + 1) begin
            fix.oned_random_launch(100);
            fix.compare_memories();
        end

        // medium transfers
        for(int i = 0; i < 200; i = i + 1) begin
            fix.oned_random_launch(1000);
            fix.compare_memories();
        end

        // long transfers
        for(int i = 0; i < 100; i = i + 1) begin
            fix.oned_random_launch(10000);
            fix.compare_memories();
        end

        // ultra long transfers
        for(int i = 0; i < 100; i = i + 1) begin
            fix.oned_random_launch(65000);
            fix.compare_memories();
        end

        $display("Done :D (in %18.9f seconds", $time() / 1000000.0);
        $display("SUCCESS");
        $stop();
    end

endmodule
