# Physically Unclonable Functions (PUFs) — Verilog & FPGA
Sem-4 Minor Project | IIIT Naya Raipur

📌 **Project Overview**

This repository contains the hardware implementation of delay-based Physically Unclonable Functions (PUFs) designed for hardware security applications. The project focuses on leveraging inherent manufacturing variations in silicon to generate unique, device-specific cryptographic signatures.

🛠️ **Technical Implementation**

The project is structured into functional modules and ongoing research components:
* **Arbiter PUF**: An 8×8 Arbiter PUF implemented with a delay-based race architecture and an 8-bit challenge–response interface.
*  Architecture: Features programmable delay elements modeled to emulate silicon path variations and a high-speed arbiter to resolve race conditions.
* **Feed-Forward (FF-PUF) & Double Feed-Forward (DFF-PUF)**: Experimental non-linear architectures currently in the research phase to address path-symmetry and signal-race complexities.

🔬 **Simulation & Verification**

The design has been rigorously validated through electronic design automation (EDA) tools:
* Toolchain: Developed and simulated using **Xilinx Vivado**
* Verification: Custom Verilog testbenches were utilized to verify functional correctness and perform detailed timing analysis.
* Waveform Analysis: Timing behavior was inspected through waveforms to ensure proper race condition resolution.
* Simulation Results: Waveform showing the 8-bit challenge input and the resulting stable 1-bit response.

🚀 **Future Work**
The project is currently transitioning to FPGA deployment (Zynq) to experimentally evaluate key PUF performance metrics:
* Uniqueness: Measuring inter-Hamming distance.
* Reliability: Analyzing intra-Hamming distance under varying conditions
