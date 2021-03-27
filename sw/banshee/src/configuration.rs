// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Configuration code to describe the simulated system architecture
//!
//! Some care is required when changing this structure, as it requires the
//! `engine.rs` and the `tran.rs` to be adapted accordingly.

/// A struct to store the whole system configuration
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct Configuration {
    #[serde(default)]
    pub memory: Memories,
    #[serde(default)]
    pub address: Address,
    #[serde(default)]
    pub inst_latency: std::collections::HashMap<String, u64>,
}

impl Default for Configuration {
    fn default() -> Configuration {
        Configuration {
            memory: Default::default(),
            address: Default::default(),
            inst_latency: Default::default(),
        }
    }
}

impl std::fmt::Display for Configuration {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}", serde_json::to_string_pretty(self).unwrap())
    }
}

impl Configuration {
    /// Parse a json file into a `Configuration` struct
    pub fn parse(name: &str) -> Configuration {
        let config: String = std::fs::read_to_string(name)
            .unwrap_or_else(|_| panic!("Could not open file {}", name))
            .parse()
            .unwrap_or_else(|_| panic!("Could not parse file {}", name));
        // Parse the configuration file based on it's name
        serde_json::from_str(&config).expect("Error while reading json")
    }
}

/// Holds all the memories in the hierarchy
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct Memories {
    pub tcdm: Memory,
    pub dram: Memory,
}

impl Default for Memories {
    fn default() -> Memories {
        Memories {
            tcdm: Memory {
                start: 0,
                end: 0x20000,
                latency: 2,
            },
            dram: Memory {
                start: 0x80000000,
                end: 0x90000000,
                latency: 10,
            },
        }
    }
}

/// Description of a single memory hierarchy
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct Memory {
    pub start: u32,
    pub end: u32,
    pub latency: u64,
}

impl Default for Memory {
    fn default() -> Memory {
        Memory {
            start: 0,
            end: u32::MAX,
            latency: 1,
        }
    }
}

/// Struct to configure specific addresses
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct Address {
    pub tcdm_start: u32,
    pub tcdm_end: u32,
    pub nr_cores: u32,
    pub scratch_reg: u32,
    pub wakeup_reg: u32,
    pub barrier_reg: u32,
    pub cluster_base_hartid: u32,
    pub cluster_num: u32,
    pub cluster_id: u32,
    pub uart: u32,
}

impl Default for Address {
    fn default() -> Address {
        Address {
            tcdm_start: 0x40000000,
            tcdm_end: 0x40000008,
            nr_cores: 0x40000010,
            scratch_reg: 0x40000020,
            wakeup_reg: 0x40000028,
            barrier_reg: 0x40000038,
            cluster_base_hartid: 0x40000040,
            cluster_num: 0x40000048,
            cluster_id: 0x40000050,
            uart: 0xF00B8000,
        }
    }
}
