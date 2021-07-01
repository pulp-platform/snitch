use crate::configuration::Func;
use PeriphsLoadStore::{Load, Store};

#[derive(Clone)]
pub struct Periphs<'a> {
    func: &'a Vec<Func>,
}

impl<'a> Periphs<'a> {
    pub fn new(func: &'a Vec<Func>) -> Self {
        Self { func }
    }

    pub fn load(&self, addr: u32, size: u8) -> u32 {
        let v = self.name(addr);
        callback_periph(v.0)(v.1, size, Load).unwrap()
    }

    pub fn store(&self, addr: u32, value: u32, size: u8) {
        let v = self.name(addr);
        callback_periph(v.0)(v.1, size, Store(value));
    }

    fn name(&self, mut addr: u32) -> (&str, u32) {
        for i in self.func {
            if addr < i.size {
                return (&i.name[..], addr);
            }
            addr = addr - i.size;
        }
        ("", addr)
    }
}

/// Argument givent to a callback function
enum PeriphsLoadStore {
    Store(u32),
    Load,
}

//########################################################################
// USER CODE
//########################################################################

/// Match the name of the peripheral in the configuration with the right callback function
fn callback_periph(name: &str) -> fn(u32, u8, PeriphsLoadStore) -> Option<u32> {
    let name = name.to_string();

    if name.eq("PERF_COUNTER_ENABLE") {
        perf_counter_enable
    } else if name.eq("HART_SELECT") {
        default
    } else if name.eq("PERF_COUNTER") {
        default
    } else if name.eq("WAKE_UP") {
        default
    } else {
        default
    }
}

// CALLBACK FUNCTIONs

fn perf_counter_enable(addr: u32, size: u8, pls: PeriphsLoadStore) -> Option<u32> {
    match pls {
        Store(s) => {
            println!(
                "{:#x} ({} byte(s)) written in PERF_COUNTER_ENABLE (@ {:#x})",
                s,
                1 << size,
                addr
            );
            None
        }
        Load => {
            println!(
                "{} byte(s) read in PERF_COUNTER_ENABLE (@ {:#x})",
                1 << size,
                addr
            );
            Some(0)
        }
    }
}

fn default(_: u32, _: u8, pls: PeriphsLoadStore) -> Option<u32> {
    match pls {
        Store(_) => {
            println!("PERIPH DEFAULT CALLBACK: Store");
            None
        }
        Load => {
            println!("PERIPH DEFAULT CALLBACK: Load");
            Some(0)
        }
    }
}
