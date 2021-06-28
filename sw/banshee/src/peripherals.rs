use PeriphsLoadStore::{Store, Load};
use crate::Configuration;
#[derive(Clone)]
pub struct Periphs {
    periphs_fn: Vec<(u32, fn(u32, PeriphsLoadStore) -> Option<u32>)>,
}

impl Periphs {
    pub fn new(config: &Configuration) -> Self {
        Self {
        periphs_fn: vec!((0, PERF_COUNTER_ENABLE)),
        }
    }
}

enum PeriphsLoadStore {
    Store(u32),
    Load,
}

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
