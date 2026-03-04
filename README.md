# Hybrid Recursive Karatsuba Algorithm Verilog Code Using 16×16 Wallace Multiplier

This repository contains the Verilog HDL implementation of a **Hybrid Recursive Karatsuba Multiplier architecture** that utilizes a **16×16 Wallace Tree Multiplier** as the base multiplication unit. The design focuses on improving multiplication speed and reducing computational complexity for large integer multiplications in digital systems.

## Project Overview

Multiplication is one of the most important operations in digital signal processing and computer arithmetic. The **Karatsuba algorithm** is an efficient divide-and-conquer multiplication technique that reduces the number of required multiplications compared to traditional methods.

In this project, a **hybrid recursive Karatsuba architecture** is implemented in Verilog where the larger multiplication problem is recursively divided into smaller parts, and a **16×16 Wallace Tree Multiplier** is used as the fundamental multiplication block for faster partial product reduction.

## Key Concepts Used

* Karatsuba multiplication algorithm
* Recursive hardware architecture
* Wallace Tree multiplier
* Partial product reduction
* High-speed arithmetic circuits

## Features

* Hybrid recursive Karatsuba multiplier implementation
* 16×16 Wallace Tree multiplier used as the base multiplication module
* Reduced multiplication complexity compared to classical methods
* Modular Verilog design
* Testbench included for simulation and verification

## Modules in the Design

* **Top Karatsuba Multiplier Module**
* **Recursive Karatsuba Blocks**
* **16×16 Wallace Tree Multiplier**
* **Partial Product Reduction Logic**
* **Adder Modules**
* **Testbench for Functional Verification**

## Tools Used

* Verilog HDL
* GTKWave for waveform analysis

## Applications

* Digital Signal Processing (DSP)
* Cryptographic hardware
* High-performance arithmetic units
* VLSI processor design
* Hardware accelerators

## Learning Outcomes

This project helps in understanding:

* Efficient multiplication algorithms in hardware
* Recursive hardware design
* Optimization of arithmetic circuits
* Implementation of Wallace Tree multipliers

## Author
Vishal Yadav
M.Tech VLSI Design
