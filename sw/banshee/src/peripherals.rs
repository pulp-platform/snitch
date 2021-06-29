use PeriphsLoadStore::{Store, Load};
use crate::Configuration;
use std::collections::HashMap;
use crate::configuration::Func;
#[derive(Clone)]
pub struct Periphs {
    //TODO use str
    periphs_fn: Vec<(u32, String)>,
}

impl Periphs {
    pub fn new(config: &Configuration) -> Self {
        Self {
            //TODO
        periphs_fn: vec!((0, "test".to_string())),
        }
    }

    pub fn load(&self, addr: u32, size: u8) -> u32 {
        0
    }

    pub fn store(&self, addr: u32, value: u32, size: u8) {
    }

}

enum PeriphsLoadStore {
    Store(u32),
    Load,
}

//########################################################################
// USER CODE
//########################################################################

fn match_name_callback(name: &str) -> fn(u32, PeriphsLoadStore) -> Option<u32>
{
    let name = name.to_string();

    if name.eq("PERF_COUNTER_ENABLE") {
        PERF_COUNTER_ENABLE
    } else if name.eq("HART_SELECT") {
        DEFAULT
    } else if name.eq("PERF_COUNTER") {
        DEFAULT
    } else if name.eq("WAKE_UP") {
        DEFAULT
    } else {
        DEFAULT
    }
}

// CALLBACK FUNCTIONs

fn PERF_COUNTER_ENABLE(addr: u32, pls: PeriphsLoadStore) -> Option<u32> {
    match pls {
        Store(s) => {
            println!("{} written in PERF_COUNTER_ENABLE (@ {})", s, addr);
            None
        }
        Load => {
            println!("Read in PERF_COUNTER_ENABLE (@ {})", addr);
            Some(0)
        }
    }
}

fn DEFAULT(addr: u32, pls: PeriphsLoadStore) -> Option<u32> {
    match pls {
        Store(s) => {
            println!("PERIPH DEFAULT CALLBACK: {} written at {}", s, addr);
            None
        }
        Load => {
            println!("PERIPH DEFAULT CALLBACK: read at {})", addr);
            Some(0)
        }
    }
}
