// Copyright 2021 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//! Configuration code to describe the simulated system architecture
//!
//! Some care is required when changing this structure, as it requires the
//! `engine.rs` and the `tran.rs` to be adapted accordingly.

use std::io::prelude::*;

/// A struct to store the whole system configuration
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct Configuration {
    #[serde(default)]
    pub memory: Memories,
    #[serde(default)]
    pub address: Address,
    #[serde(default)]
    pub inst_latency: std::collections::HashMap<String, u64>,
    #[serde(default)]
    pub ssr: Ssr,
}

impl Default for Configuration {
    fn default() -> Configuration {
        Configuration {
            memory: Default::default(),
            address: Default::default(),
            inst_latency: Default::default(),
            ssr: Default::default(),
        }
    }
}

impl std::fmt::Display for Configuration {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}", serde_yaml::to_string(self).unwrap())
    }
}

impl Configuration {
    /// Parse a json/yaml file into a `Configuration` struct
    pub fn parse(name: &str) -> Configuration {
        let config: String = std::fs::read_to_string(name)
            .unwrap_or_else(|_| panic!("Could not open file {}", name))
            .parse()
            .unwrap_or_else(|_| panic!("Could not parse file {}", name));
        // Parse the configuration file based on it's name
        if name.to_lowercase().contains("json") {
            serde_json::from_str(&config).expect("Error while reading json")
        } else {
            serde_yaml::from_str(&config).expect("Error while reading yaml")
        }
    }

    /// Write the default `Configuration` struct into a json/yaml file
    pub fn print_default(name: &str) -> std::io::Result<()> {
        let mut f = std::fs::File::create(name)?;
        let mut c = serde_json::to_value(Configuration::default()).unwrap();
        let i = c.get_mut("inst_latency").unwrap();
        let l = crate::riscv::Latency::default();
        *i = serde_json::to_value(l).unwrap();
        warn!("{:?}", c);

        if name.to_lowercase().contains("json") {
            f.write_all(serde_json::to_string_pretty(&c).unwrap().as_bytes())?;
        } else {
            f.write_all(serde_yaml::to_string(&c).unwrap().as_bytes())?;
        }
        Ok(())
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

/// Struct to configure SSRs
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct Ssr {
    pub num_dm: usize,
}

impl Default for Ssr {
    fn default() -> Ssr {
        Ssr { num_dm: 2 }
    }
}
