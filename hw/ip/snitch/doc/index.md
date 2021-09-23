# Snitch

Snitch is a single-stage, single-issue, in-order RISC-V core (RV32I or RV32E)
tuned for simplicity and minimal area footprint. Furthermore it is highly
configurable and can be used in a plethora of different applications.

The core has an optional accelerator interface which can be used to control and
off-load RISC-V instructions. The load/store interface is a dual-channel
interface with a separately handshaked request and response channel. More
information can be found [here](../../rm/reqrsp_interface).

This folder contains the main Snitch core, incl. L0 translation lookaside buffer
(TLB), register file and load store unit (LSU).

!!! info
    The virtual memory support in Snitch is still in a very early, untested stage
    so do not expect it to work yet.

## Core Integration

This section covers integration aspects of the core.

### File List

We use `Bender` to generate the file lists for the modules. To get stated with
the Snitch core and a file list you can:

- In `hw/ip/snitch`, call `bender sources` (or `bender script flist` for a flat
  file list).
- If you also want to use bender for your project you can create a minimal
  bender manifest with a path dependency to the Snitch core. For an example
  please have a look at `hw/system/snitch_cluster/Bender.yml`.

### Parameters

| Name                     | Type/Range | Default | Description                                                                                                                                              |
| ------------------------ | ---------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AddrWidth`              | int        | 48      | Address width of the system.                                                                                                                             |
| `DataWidth`              | int        | 64      | Data width of the data bus. Can either be `32` or `64`.                                                                                                  |
| `acc_req_t`              | type       | logic   | Type of accelerator request port. See `snitch_pkg.sv` for an example. **Must be set to a meaningful type.**                                              |
| `acc_resp_t`             | type       | logic   | Type of accelerator response port. See `snitch_pkg.sv` for an example. **Must be set to a meaningful type.**                                             |
| `dreq_t`                 | type       | logic   | Type of data request port. See `hw/ip/reqrsp_intf` for examples and typedef helper functions. **Must be set to a meaningful type.**                      |
| `drsp_t`                 | type       | logic   | Type of data response port. See `hw/ip/reqrsp_intf` for examples and typedef helper functions. **Must be set to a meaningful type.**                     |
| `pa_t`                   | type       | logic   | Type of physical address. See `hw/ip/snitch_vm` for examples and typedef helper functions. **Must be set to a meaningful type.**                         |
| `l0_pte_t`               | type       | logic   | Type of L0 page table entry. See `hw/ip/snitch_vm` for examples and typedef helper functions. **Must be set to a meaningful type.**                      |
| `BootAddr`               | int        | 0x1000  | Address where the core starts to fetch for instruction after reset.                                                                                      |
| `SnitchPMACfg`           | struct     | '0      | Physical memory attribute configuration.                                                                                                                 |
| `NumIntOutstandingLoads` | int        | 0       | Number of outstanding loads. This determines the size of the load queue.                                                                                 |
| `NumIntOutstandingMem`   | int        | 0       | Number of outstanding memory operations (loads *and* stores).                                                                                            |
| `NumDTLBEntries`         | int        | 0       | Number of TLB entries for the data TLB.                                                                                                                  |
| `NumITLBEntries`         | int        | 0       | Number of TLB entries for the instruction TLB.                                                                                                           |
| `RVE`                    | bit        | 0       | Enable embedded ABI (reduced register ABI).                                                                                                              |
| `FP_EN`                  | bit        | 0       | Enable floating point support (in general).                                                                                                              |
| `Xdma`                   | bit        | 0       | Enable custom DMA extension (changes the decoder of the core).                                                                                           |
| `Xssr`                   | bit        | 0       | Enable custom SSR extension (changes the decoder of the core).                                                                                           |
| `RVF`                    | bit        | 0       | Enable single-precision floating point extension (needs `FP_EN`).                                                                                        |
| `RVD`                    | bit        | 0       | Enable double-precision floating point extension (needs `FP_EN`).                                                                                        |
| `XF16`                   | bit        | 0       | Enable half-precision floating point extension (needs `FP_EN`).                                                                                          |
| `XF16ALT`                | bit        | 0       | Enable brain-float extension (needs `FP_EN`).                                                                                                            |
| `XF8`                    | bit        | 0       | Enable eight byte floating-point extensions (needs `FP_EN`).                                                                                             |
| `XF8ALT`                 | bit        | 0       | Enable alternate eight byte floating-point extensions (needs `FP_EN`).                                                                                   |
| `XFVEC`                  | bit        | 0       | Enable vectorized extension (needs `FP_EN`).                                                                                                             |
| `XFDOTP`                 | bit        | 0       | Enable DOTP operation group (needs `FP_EN`).                                                                                                             |
| `FLEN`                   | bit        | 0       | Required floating-point length (depends on enabled extension). Determined by the maximum floating-point length (`64` for double, `32` for single, etc.). |

### Ports

| Signals          | Width               | Dir | Description                                                                                                       |
| ---------------- | ------------------- | --- | ----------------------------------------------------------------------------------------------------------------- |
| clk_i            | `1`                 | In  | Clock.                                                                                                            |
| rst_i            | `1`                 | In  | Reset, asynchronous, active-high.                                                                                 |
| hart_id_i        | `32`                | In  | Id present in `mhartid`.                                                                                          |
| irq_i            | `3`                 | In  | M-Mode timer, software, and external interrupt.                                                                   |
| flush_i_valid_o  | `1`                 | In  | Flush the instruction cache (`fence.i`). Once high wait for `flush_i_ready_i` is asserted. *AXI-style handshake.* |
| flush_i_ready_i  | `1`                 | In  | Instruction cache is ready.                                                                                       |
| inst_addr_o      | `AddrWidth`         | Out | Instruction address.                                                                                              |
| inst_cacheable_o | `1`                 | Out | If asserted high, the instruction should be cached.                                                               |
| inst_data_i      | `32`                | In  | 32-bit RISC-V instruction word.                                                                                   |
| inst_valid_o     | `1`                 | Out | Instruction request is valid.                                                                                     |
| inst_ready_i     | `1`                 | In  | Instruction word has been consumed.                                                                               |
| acc_qreq_o       | `bits(acc_req_t)`   | Out | Accelerator off-load information.                                                                                 |
| acc_qvalid_o     | `1`                 | Out | Accelerator off-load request is valid. *AXI-style handshake.*                                                     |
| acc_qready_i     | `1`                 | In  | Request has been accepted.                                                                                        |
| acc_prsp_i       | `bits(acc_resp_t)`  | In  | Accelerator response information.                                                                                 |
| acc_pvalid_i     | `1`                 | In  | Accelerator response is valid. *AXI-style handshake.*                                                             |
| acc_pready_o     | `1`                 | Out | Accelerator response has been accepted by the core.                                                               |
| data_req_o       | `bits(dreq_t)`      | Out | Load/store request. See [reqrsp interface](../../rm/reqrsp_interface).                                            |
| data_rsp_i       | `bits(drsp_t)`      | In  | Load/store response. See [reqrsp interface](../../rm/reqrsp_interface).                                           |
| wake_up_sync_i   | `1`                 | In  | Deprecated. Tie-low.                                                                                              |
| ptw_valid_o      | `2`                 | Out | Instruction or data TLB missed. Page table walking request.                                                       |
| ptw_ready_i      | `2`                 | In  | Instruction or data miss has been accepted.                                                                       |
| ptw_va_o         | `2*bits(va_t)`      | Out | Instruction or data virtual address requested to be translated.                                                   |
| ptw_ppn_o,       | `2*bits(pa_t)`      | Out | Instruction or data physical base address. Forwarded from `satp` register.                                        |
| ptw_pte_i,       | `2*bits(l0_pte_t)`  | In  | Instruction or data PTE entry in (translated virtual address).                                                    |
| ptw_is_4mega_i,  | `2`                 | In  | Instruction or data PTE is a 4 mega page.                                                                         |
| fpu_rnd_mode_o   | `bits(roundmode_e)` | Out | Side-band signal forwarding the rounding mode from `fcsr`.                                                        |
| fpu_status_i     | `bits(status_t)`    | In  | Exception status of FPU (can be tied to `0` if no FPU is used).                                                   |

### Instantiation Template

```systemverilog
  snitch #(
    .AddrWidth (),
    .DataWidth (),
    .acc_req_t (),
    .acc_resp_t (),
    .dreq_t (),
    .drsp_t (),
    .pa_t (pa_t,
    .l0_pte_t (),
    .BootAddr (),
    .SnitchPMACfg (),
    .NumIntOutstandingLoads (),
    .NumIntOutstandingMem (),
    .NumDTLBEntries (),
    .NumITLBEntries (),
    .RVE (),
    .FP_EN (),
    .Xdma (),
    .Xssr (),
    .RVF (),
    .RVD (),
    .XF16 (),
    .XF16ALT (),
    .XF8 (),
    .XF8ALT (),
    .XFVEC (),
    .XFDOTP (),
    .FLEN ()
  ) i_snitch (
    .clk_i ( ),
    .rst_i (),
    .hart_id_i (),
    .irq_i (),
    .flush_i_valid_o (),
    .flush_i_ready_i (),
    .inst_addr_o (),
    .inst_cacheable_o (),
    .inst_data_i (),
    .inst_valid_o (),
    .inst_ready_i (),
    .acc_qreq_o (),
    .acc_qvalid_o (),
    .acc_qready_i (),
    .acc_prsp_i (),
    .acc_pvalid_i (),
    .acc_pready_o (),
    .data_req_o (),
    .data_rsp_i (),
    .ptw_valid_o (),
    .ptw_ready_i (),
    .ptw_va_o (),
    .ptw_ppn_o (),
    .ptw_pte_i (),
    .ptw_is_4mega_i (),
    .wake_up_sync_i (),
    .fpu_rnd_mode_o (),
    .fpu_status_i ()
  );
```

## Testbench

- The L0 TLBs: Random requests are generated. The golden model saves all
  requests, if a new request comes in it is either sourced from memory (if it
  exists) or re-generated based on constraint randomization. Response from the
  DUT are compared to the golden model.
