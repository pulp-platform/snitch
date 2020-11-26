# TCDM Interconnect

The `tcdm_interconnect` module provides three different low-latency interconnect topologies for architectures like the PULP-cluster, where we would like to route single cycle transactions from N Master agents (Cores) to M Slaves (Banks). We refer to such an interconnect parameterisation as an N x M instance in the following. This setting has a couple of constraints which makes interconnect design challenging:

- No complicated arbitration possible as information would have to be gathered
- Timing
- Routing
- Complexity, Scalability

This readme describes the available networks in detail, and summarizes the results of a parametric design space exploration of instances ranging from 8 x 8 to 256 x 1024.

AMO shim

<!-- ![](docs/img/ariane_overview.png) -->

<!-- Table of Contents -->
<!-- ================= -->


<!-- Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc) -->

<!-- pointer to testbench readme -->

## Overview

## Network Architectures

### Full Crossbar (Logarithmic Interconnect)

### Butterfly

### Clos Network

## Design Space Exploration

### Methodology

### Traffic Simulations

#### Clos

![stats_clos_32x](../../tb/tb_tcdm_interconnect/plots/stats_clos_32x.png)

#### Butterfly's

![stats_selection_8x](../../tb/tb_tcdm_interconnect/plots/stats_selection_8x.png)
![stats_selection_16x](../../tb/tb_tcdm_interconnect/plots/stats_selection_16x.png)
![stats_selection_32x](../../tb/tb_tcdm_interconnect/plots/stats_selection_32x.png)
![stats_selection_64x](../../tb/tb_tcdm_interconnect/plots/stats_selection_64x.png)
![stats_selection_128x](../../tb/tb_tcdm_interconnect/plots/stats_selection_128x.png)
![stats_selection_256x](../../tb/tb_tcdm_interconnect/plots/stats_selection_256x.png)


### Pareto Analysis

#### Random Uniform Traffic

![pareto_random_uniform_8x](../../tb/tb_tcdm_interconnect/plots/pareto_random_uniform_8x.png)
![pareto_random_uniform_16x](../../tb/tb_tcdm_interconnect/plots/pareto_random_uniform_16x.png)
![pareto_random_uniform_32x](../../tb/tb_tcdm_interconnect/plots/pareto_random_uniform_32x.png)
![pareto_random_uniform_64x](../../tb/tb_tcdm_interconnect/plots/pareto_random_uniform_64x.png)
![pareto_random_uniform_128x](../../tb/tb_tcdm_interconnect/plots/pareto_random_uniform_128x.png)
![pareto_random_uniform_256x](../../tb/tb_tcdm_interconnect/plots/pareto_random_uniform_256x.png)

#### Random Linear Traffic

![pareto_random_linear_8x](../../tb/tb_tcdm_interconnect/plots/pareto_random_linear_8x.png)
![pareto_random_linear_16x](../../tb/tb_tcdm_interconnect/plots/pareto_random_linear_16x.png)
![pareto_random_linear_32x](../../tb/tb_tcdm_interconnect/plots/pareto_random_linear_32x.png)
![pareto_random_linear_64x](../../tb/tb_tcdm_interconnect/plots/pareto_random_linear_64x.png)
![pareto_random_linear_128x](../../tb/tb_tcdm_interconnect/plots/pareto_random_linear_128x.png)
![pareto_random_linear_256x](../../tb/tb_tcdm_interconnect/plots/pareto_random_linear_256x.png)

### Scalability Analysis

![scaling_bf1](../../tb/tb_tcdm_interconnect/plots/scaling_bf1.png)
![scaling_bf2](../../tb/tb_tcdm_interconnect/plots/scaling_bf2.png)
![scaling_bf4](../../tb/tb_tcdm_interconnect/plots/scaling_bf4.png)

References??

