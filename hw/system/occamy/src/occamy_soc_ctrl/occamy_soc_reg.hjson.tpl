// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
// Licensed under Solderpad Hardware License, Version 0.51, see LICENSE for details.
{
  param_list: [
    { name: "NumScratchRegs",
      desc: "Number of scratch registers",
      type: "int",
      default: "4"
    },
    { name: "NumPads",
      desc: "Number of GPIO pads in the chip.",
      type: "int",
      default: "31"
    },
  ],
  name: "Occamy_SoC"
  clock_primary: "clk_i"
  bus_interfaces: [
    { protocol: "reg_iface", direction: "device" }
  ],
  interrupt_list: [
    { name: "ecc_uncorrectable"
      desc: "Detected an uncorrectable ECC error on system SRAM."}
    { name: "ecc_correctable"
      desc: "Detected a correctable ECC error on system SRAM."}
  ]
  regwidth: 32
  registers: [
    { name: "VERSION"
      desc: "Version register, should read 1."
      swaccess: "ro"
      hwaccess: "none"
      fields: [
        {
          bits: "15:0"
          resval: "1"
          name: "VERSION"
          desc: '''
                System version.
                '''
        }
      ]
    }
    { name: "CHIP_ID"
      desc: "Id of chip for multi-chip systems."
      swaccess: "ro"
      hwaccess: "hwo"
      hwqe:     "true",
      hwext:    "true",
      fields: [
        {
          bits: "1:0"
          resval: "0"
          name: "CHIP_ID"
          desc: '''
                Id of chip for multi-chip systems.
                '''
        }
      ]
    }
    { multireg:
      { name: "SCRATCH"
        desc: "Scratch register for SW to write to."
        swaccess: "rw"
        hwaccess: "none"
        count: "NumScratchRegs"
        cname: "scratch"
        fields: [
          { bits: "31:0"
            resval: "0"
            name: "SCRATCH"
            desc: '''
                  Scratch register for software to read/write.
                  '''
          }
        ]
      }
    }
    { name: "BOOT_MODE",
      desc: "Selected boot mode exposed a register.",
      swaccess: "ro",
      hwaccess: "hwo",
      hwqe:     "true",
      hwext:    "true",
      fields: [
        { bits: "1:0"
          name: "MODE"
          desc: "Selected boot mode."
          enum: [
               { value: "0", name: "idle", desc: "Governor idles in bootrom." },
               { value: "1", name: "serial", desc: "Governor jumps to the base of the serial." },
               { value: "2", name: "i2c", desc: "Governor tries to boot from I2C." }
          ]
        }
      ]
    }
    { multireg:
      { name: "PAD"
        desc: "GPIO pad configuration."
        swaccess: "rw"
        hwaccess: "hro",
        count: "NumPads"
        cname: "pad"
        fields: [
          { bits: "0"
            name: "SLW"
            resval: "0"
            desc: '''
                    Slew control.
                    1: when VDDIO = 1.5/1.2V
                    0: when VDDIO = 1.8V
                  '''
          },
          { bits: "1"
            name: "SMT"
            resval: "0"
            desc: "Active high Schmitt Trigger enable."
          },
          { bits: "3:2"
            name: "DRV"
            resval: "2"
            desc: "Drive strength."
          }
        ]
      }
    }
  ]
}
