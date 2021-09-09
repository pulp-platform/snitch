// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
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
    { name: "NumS1Quadrants",
      desc: "Number of S1 Quadrants.",
      type: "int",
      default: "${nr_s1_quadrants}"
    },
  ],
  name: "Occamy SoC"
  clock_primary: "clk_i"
  bus_device: "reg"
  bus_host: "none"
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
    { multireg:
      { name: "ISOLATE"
        desc: "Isolate port of given quadrant."
        swaccess: "rw"
        hwaccess: "hro"
        count: "NumS1Quadrants"
        cname: "isolate"
        fields: [
          { bits: "3:0"
            resval: "1"
            name: "ISOLATE"
            desc: '''
                  Isolate S1 Quadrant. Four bits corresponding to:
                    - Bit 0: Narrow In
                    - Bit 1: Narrow Out
                    - Bit 2: Wide In
                    - Bit 3: Wide Out

                  0: De-isolate request
                  1: Isolate request
                  '''
          }
        ]
      }
    },
    { multireg:
      { name: "ISOLATED"
        desc: "Isolation status of S1 quadrant and port"
        swaccess: "ro"
        hwaccess: "hwo"
        hwqe:     "true",
        hwext:    "true",
        count: "NumS1Quadrants"
        cname: "isolated"
        fields: [
          { bits: "3:0"
            resval: "1"
            name: "ISOLATED"
            desc: '''
                  Isolate satus of S1 Quadrant. Four bits corresponding to:
                    - Bit 0: Narrow In
                    - Bit 1: Narrow Out
                    - Bit 2: Wide In
                    - Bit 3: Wide Out

                  Isolation status:
                    0: De-isolated
                    1: Isolated
                  '''
          }
        ]
      }
    },
    { multireg:
      { name: "RO_CACHE_ENABLE",
        desc: "Enable read-only cache of quadrant.",
        swaccess: "rw"
        hwaccess: "hro"
        count: "NumS1Quadrants"
        cname: "ro_enable"
        fields: [
          { bits: "0:0"
            resval: "0"
            name: "ENABLE"
            desc: "Enable RO cache of S1 quadrant."
          }
        ]
      },
    },
    { multireg:
      { name: "RO_CACHE_FLUSH",
        desc: "Flush read-only cache.",
        swaccess: "rw"
        hwaccess: "hrw"
        count: "NumS1Quadrants"
        cname: "ro_flush"
        fields: [
          { bits: "0:0"
            resval: "0"
            name: "FLUSH"
            desc: "Flush (invalidate) RO cache of S1 quadrant."
          }
        ]
      }
    },
    { skipto: "0x100" },
% for i in range(nr_s1_quadrants):
% for j in range(cfg["s1_quadrant"].get("ro_cache_cfg", {}).get("address_regions", 1)):
    { name: "RO_START_ADDR_LOW_${j}_QUADRANT_${i}",
      desc: "Read-only cache start address low",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "31:0"
        name: "ADDR_LOW"
        desc: "Lower 32-bit of read-only region."
        }
      ]
    },
    { name: "RO_START_ADDR_HIGH_${j}_QUADRANT_${i}",
      desc: "Read-only cache start address high",
      swaccess: "rw",
      hwaccess: "hro",
      resval: ${j}
      fields: [
        { bits: "${soc_wide_xbar.aw-33}:0"
        name: "ADDR_HIGH"
        desc: "Higher 32-bit of read-only region."
        }
      ]
    }
    { name: "RO_END_ADDR_LOW_${j}_QUADRANT_${i}",
      desc: "Read-only cache end address low",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "31:0"
        name: "ADDR_LOW"
        desc: "Lower 32-bit of read-only region."
        }
      ]
    },
    { name: "RO_END_ADDR_HIGH_${j}_QUADRANT_${i}",
      desc: "Read-only cache end address high",
      swaccess: "rw",
      hwaccess: "hro",
      resval: ${j + 1}
      fields: [
        { bits: "${soc_wide_xbar.aw-33}:0"
        name: "ADDR_HIGH"
        desc: "Higher 32-bit of read-only region."
        }
      ]
    }
% endfor
% endfor
  ]
}
