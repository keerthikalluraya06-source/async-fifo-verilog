## Asynchronous FIFO Design and CDC Verification

## Overview
This repository contains the RTL design and verification of an Asynchronous FIFO (First-In-First-Out) memory buffer. It safely transfers data between two independent clock domains, which is a critical requirement in modern VLSI systems. 

## Design Specifications
* Data Width: 8 bits
* FIFO Depth: 8 entries
* Clocking: Independent Read and Write clocks (Asynchronous)
* Pointers: Gray-code read and write pointers for safe Clock Domain Crossing (CDC)
* Synchronization: Two-stage synchronizers (flip-flops) to prevent metastability
* Flags: FULL and EMPTY flag logic to prevent data overwrite and garbage reads

## Verification Environment
The design was verified using ModelSim Intel FPGA Starter Edition 2020.1. 

The included testbench (`async_fifo_tb.v`) is a self-checking testbench that automatically verifies:
1. Reset Behavior: Asserts the `empty` flag and safely clears the buffer.
2. Data Integrity: Ensures data written is read back in exact FIFO order.
3. Overflow Protection: Attempts to write past the 8-entry depth, verifying the `full` flag asserts and prevents data loss.
4. Underflow Protection: Attempts to read from an empty FIFO, verifying the `empty` flag asserts and prevents garbage data from leaking.
