// Copyright 2020 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use bytebuffer::ByteBuffer;
use byteorder::{BigEndian, LittleEndian, ReadBytesExt};
use std::{
    collections::HashMap,
    env,
    error::Error,
    fs,
    fs::File,
    io::prelude::*,
    io::{BufReader, ErrorKind, Read, Seek, SeekFrom, Write},
    process,
    str::FromStr,
    sync::{
        atomic::{AtomicBool, AtomicU32, AtomicUsize, Ordering},
        Mutex,
    },
};
use to_binary::{BinaryError, BinaryString};

pub fn generic_bin_read<const N: usize>(
    bin_path: &str,
    mut offset: u64,
) -> Result<HashMap<u64, u32>, Box<dyn Error>> {
    // we will return a HashMap of addresses to values
    // which we use to extend the DRAM
    let mut result = HashMap::<u64, u32>::new();

    // we read in the binary data from the file into a buffer
    let mut bin_buf = BufReader::new(File::open(bin_path).unwrap());

    // we define the buffer in which we read in single values
    // we always have to read in 32 bits into memory for the DRAM
    let mut exact_buf = [0u8; N];

    loop {
        if let Err(e) = bin_buf.read_exact(&mut exact_buf) {
            if e.kind() == ErrorKind::UnexpectedEof {
                break;
            } else {
                panic!("Error reading file: {}", e);
            }

            return Err(e.into());
        }

        // we convert the buffer into a u32
        let mut bit_buffer: &[u8] = &exact_buf;
        let u32_value = bit_buffer.read_u32::<LittleEndian>().unwrap();
        trace!("u32_value: {:#034b}", u32_value);

        // we add the address to the HashMap
        result.insert(offset, u32_value);
        // and increment the offset by the word width
        offset += 4;
    }

    // return the result
    Ok(result)
}
