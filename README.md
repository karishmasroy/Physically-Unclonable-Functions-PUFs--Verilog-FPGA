# 64-bit Arbiter PUF Hardware Security Implementation
This repository contains the design, implementation, and statistical analysis of a 64-bit Strong Arbiter Physically Unclonable Function (PUF) deployed on FPGA hardware. The project explores the intersection of hardware security, silicon process variation, and architectural mitigation strategies.

## 🚀 **Scaling to 64-bit: Why it Matters**

While 8-bit implementations serve as functional proofs-of-concept, scaling to a 64-bit challenge interface is essential for cryptographic robustness.
* **Expanded Challenge Space:** Moving from 2^8 to 2^{64} challenge-response pairs (CRPs) prevents brute-force database reconstruction.
* **Strong PUF" Classification:** A 64-bit architecture provides a challenge space so vast it cannot be fully enumerated within the device's lifetime.
* **Modeling Attack Resistance:** The increased complexity raises the barrier for Machine Learning-based modeling attacks, requiring higher-order data for successful prediction.

## 🛠️ **Hardware Prototype & Setup**

The design is implemented and validated on the Xilinx Zynq-7000 (ZedBoard) platform.
**System Architecture**
* **PUF Core:** 64-stage delay-based race architecture in Verilog.
*  **Post-Processing:** Integrated 8-input XOR layer to isolate silicon variation from deterministic bias.
* **Interface:** Custom Python-UART framework for high-throughput CRP acquisition.


https://github.com/user-attachments/assets/a0dc5d02-d012-47f1-aa09-416f8524dc14

## 📊** Performance Metrics**

Statistical evaluation was conducted across 4 FPGAs with 28 experimental datasets consisting of over 280,000 CRPs.
<img width="480" height="149" alt="Screenshot 2026-04-10 130900" src="https://github.com/user-attachments/assets/2f5c444d-b09f-4616-8de9-315f564e5ac2" />

## 🔍 **Root Cause Analysis: The "Routing Bias" Problem**

Despite near-ideal uniformity and reliability, Uniqueness and Bit-Aliasing are heavily impacted by the physical constraints of the FPGA fabric.
**System Architecture**
* **Deterministic Skew:** The Vivado router prioritizes timing closure over path symmetry, creating fixed sub-nanosecond "Deltas" that favor specific paths across all devices.
*  **Impact:** These universal routing offsets drown out the unique silicon fingerprint, causing devices to behave as clones (high aliasing).

<img width="611" height="150" alt="Screenshot 2026-04-07 093805" src="https://github.com/user-attachments/assets/47c6998a-b808-4249-887f-1a61c92ee748" />



## ⚡**Hardware Efficiency**
* **Logic Footprint:** Minimal utilization of **609 LUTs (1.14% of ZedBoard resources).**
*  **Power Profile:** Ultra-low active overhead with a dynamic power draw of only **3mW.**

## **🎓 Academic Credits**
Developed by **Karishma Singha Roy** as part of undergraduate research in Electronics and Communication Engineering at IIIT Naya Raipur.
