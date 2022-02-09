# Address Map

This is the current address map of occamy. Note that the Quadrants address map has its own table below.

## Occamy Address Map

|     Name      |   Size   | Status |       Start       |        End        |
| ------------- | -------: | :----: | ----------------: | ----------------: |
| DEBUG         |   4.0 KB |  used  |      0x0000\_0000 |      0x0000\_0fff |
| -             |  16.0 MB |  free  |      0x0000\_1000 |      0x00ff\_ffff |
| BOOTROM       | 128.0 KB |  used  |      0x0100\_0000 |      0x0101\_ffff |
| -             |  15.9 MB |  free  |      0x0102\_0000 |      0x01ff\_ffff |
| SOC\_CTRL     |   4.0 KB |  used  |      0x0200\_0000 |      0x0200\_0fff |
| CLK\_MGR      |   4.0 KB |  used  |      0x0200\_1000 |      0x0200\_1fff |
| UART          |   4.0 KB |  used  |      0x0200\_2000 |      0x0200\_2fff |
| GPIO          |   4.0 KB |  used  |      0x0200\_3000 |      0x0200\_3fff |
| I2C           |   4.0 KB |  used  |      0x0200\_4000 |      0x0200\_4fff |
| CHIP\_CTRL    |   4.0 KB |  used  |      0x0200\_5000 |      0x0200\_5fff |
| TIMER         |   4.0 KB |  used  |      0x0200\_6000 |      0x0200\_6fff |
| -             |  16.0 MB |  free  |      0x0200\_7000 |      0x02ff\_ffff |
| SPIM          | 128.0 KB |  used  |      0x0300\_0000 |      0x0301\_ffff |
| -             |  15.9 MB |  free  |      0x0302\_0000 |      0x03ff\_ffff |
| CLINT         |   1.0 MB |  used  |      0x0400\_0000 |      0x040f\_ffff |
| -             |  15.0 MB |  free  |      0x0410\_0000 |      0x04ff\_ffff |
| PCIE\_CFG     | 128.0 KB |  used  |      0x0500\_0000 |      0x0501\_ffff |
| -             |  15.9 MB |  free  |      0x0502\_0000 |      0x05ff\_ffff |
| HBI\_CFG      |  64.0 KB |  used  |      0x0600\_0000 |      0x0600\_ffff |
| -             |  15.9 MB |  free  |      0x0601\_0000 |      0x06ff\_ffff |
| HBI\_CTL      |  64.0 KB |  used  |      0x0700\_0000 |      0x0700\_ffff |
| -             |  15.9 MB |  free  |      0x0701\_0000 |      0x07ff\_ffff |
| HBM\_CFG      |   4.0 MB |  used  |      0x0800\_0000 |      0x083f\_ffff |
| -             |  12.0 MB |  free  |      0x0840\_0000 |      0x08ff\_ffff |
| HBM\_PHY\_CFG |   1.0 MB |  used  |      0x0900\_0000 |      0x090f\_ffff |
| -             |  15.0 MB |  free  |      0x0910\_0000 |      0x09ff\_ffff |
| HBM\_SEQ      |  64.0 KB |  used  |      0x0a00\_0000 |      0x0a00\_ffff |
| -             |  15.9 MB |  free  |      0x0a01\_0000 |      0x0aff\_ffff |
| QUAD\_0\_CFG  |  64.0 KB |  used  |      0x0b00\_0000 |      0x0b00\_ffff |
| -             |  15.9 MB |  free  |      0x0b01\_0000 |      0x0bff\_ffff |
| PLIC          |  64.0 MB |  used  |      0x0c00\_0000 |      0x0fff\_ffff |
| QUADRANTS     |   1.0 MB |  used  |      0x1000\_0000 |      0x100f\_ffff |
| -             | 255.0 MB |  free  |      0x1010\_0000 |      0x1fff\_ffff |
| PCIE          | 640.0 MB |  used  |      0x2000\_0000 |      0x47ff\_ffff |
| PCIE          | 640.0 MB |  used  |      0x4800\_0000 |      0x6fff\_ffff |
| SPM           | 128.0 KB |  used  |      0x7000\_0000 |      0x7001\_ffff |
| -             | 255.9 MB |  free  |      0x7002\_0000 |      0x7fff\_ffff |
| HBM\_0        |   1.0 GB |  used  |      0x8000\_0000 |      0xbfff\_ffff |
| HBM\_1        |   1.0 GB |  used  |      0xc000\_0000 |      0xffff\_ffff |
| -             |  60.0 GB |  free  |   0x1\_0000\_0000 |   0xf\_ffff\_ffff |
| HBM\_0        |   1.0 GB |  used  |  0x10\_0000\_0000 |  0x10\_3fff\_ffff |
| HBM\_1        |   1.0 GB |  used  |  0x10\_4000\_0000 |  0x10\_7fff\_ffff |
| HBM\_2        |   1.0 GB |  used  |  0x10\_8000\_0000 |  0x10\_bfff\_ffff |
| HBM\_3        |   1.0 GB |  used  |  0x10\_c000\_0000 |  0x10\_ffff\_ffff |
| HBM\_4        |   1.0 GB |  used  |  0x11\_0000\_0000 |  0x11\_3fff\_ffff |
| HBM\_5        |   1.0 GB |  used  |  0x11\_4000\_0000 |  0x11\_7fff\_ffff |
| HBM\_6        |   1.0 GB |  used  |  0x11\_8000\_0000 |  0x11\_bfff\_ffff |
| HBM\_7        |   1.0 GB |  used  |  0x11\_c000\_0000 |  0x11\_ffff\_ffff |
| -             | 952.0 GB |  free  |  0x12\_0000\_0000 |  0xff\_ffff\_ffff |
| HBI           |   1.0 TB |  used  | 0x100\_0000\_0000 | 0x1ff\_ffff\_ffff |


## Quadrants Address Map

| Quadrant | Cluster |        Name         |   Size   |    Start     |     End      |
| :------: | :-----: | ------------------- | -------: | -----------: | -----------: |
|    0     |    0    | CLUSTER\_TCDM       | 128.0 KB | 0x1000\_0000 | 0x1001\_ffff |
|    0     |    0    | CLUSTER\_PERIPHERAL | 128.0 KB | 0x1002\_0000 | 0x1003\_ffff |
|    0     |    1    | CLUSTER\_TCDM       | 128.0 KB | 0x1004\_0000 | 0x1005\_ffff |
|    0     |    1    | CLUSTER\_PERIPHERAL | 128.0 KB | 0x1006\_0000 | 0x1007\_ffff |
|    0     |    2    | CLUSTER\_TCDM       | 128.0 KB | 0x1008\_0000 | 0x1009\_ffff |
|    0     |    2    | CLUSTER\_PERIPHERAL | 128.0 KB | 0x100a\_0000 | 0x100b\_ffff |
|    0     |    3    | CLUSTER\_TCDM       | 128.0 KB | 0x100c\_0000 | 0x100d\_ffff |
|    0     |    3    | CLUSTER\_PERIPHERAL | 128.0 KB | 0x100e\_0000 | 0x100f\_ffff |
|    -     |    -    | EMPTY               | 255.0 MB | 0x1010\_0000 | 0x1fff\_ffff |

