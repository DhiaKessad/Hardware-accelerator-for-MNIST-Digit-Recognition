# Hardware-Accelerated Digit Recognition (Virtex-6)

This repository contains a full **Hardware-Software Co-Design** pipeline for handwritten digit recognition. 
It bridges the gap between high-level deep learning and low-level FPGA implementation by providing tools to train, quantize,
and export a Multi-Layer Perceptron (MLP) into formats ready for **Xilinx BRAM** and **Verilog logic**.

## Project Overview
The goal is to deploy a 2-layer MLP on a **Xilinx Virtex-6 (ML605)**. To ensure high performance on hardware, 
the model is converted from 32-bit floating-point to **8-bit signed fixed-point** integers.

### Key Technical Features:
- **Neural Network Architecture**: 784 (Input) → 128 (Hidden) → 10 (Output).
- **8-Bit Quantization**: Custom scaling logic to maximize precision within an 8-bit range (-128 to 127).
- **Weight Storage**: Generated `.coe` files for initializing Xilinx Block RAM (BRAM).
- **Bias Integration**: Generated `.vh` (Verilog Header) files to define biases as hardcoded parameters for zero-latency addition.
- **Verification**: Python-based inference scripts to verify raw `.hex` image data against the "Golden Model."

---

## Repository Structure

| File | Description |
| :--- | :--- |
| `model.py` | PyTorch definition of the `SimpleMLP` architecture. |
| `train.py` | Training script that outputs `mnist_weights.pth`. |
| `export_utils.py` | **The Bridge**: Quantizes weights/biases and generates `.coe`, `.txt`, and `.vh` files. |
| `run_inference.py` | Hardware-in-the-loop verification using raw `.hex` test images. |
| `check_env.py` | Script to verify the Python environment and package versions. |
| `requirements.txt` | List of Python dependencies (PyTorch, NumPy, etc.). |
| `.gitignore` | Configured to exclude OS junk (`.DS_Store`) and Python cache. |

---



## Usage Instructions

### 1. Setup Environment
Ensure you are using Python 3.12+ and have installed the required libraries:
```bash
pip install -r requirements.txt
python check_env.py
```
### 2.Train and Export
Generate the necessary hardware memory files:
```bash
# Train the model
python train.py

# Export weights and biases for Verilog/Vivado
python export_utils.py
```
This will produce `fc1_weight.coe`, `fc2_weight.coe`, and the bias header files (`fc1_bias.vh`, `fc2_bias.vh`).

### 3. Verification
Test the quantized model against raw pixel data (hex) intended for the FPGA testbench:
```bash
python run_inference.py
```
## Hardware Specifications (Target: Virtex-6)
- **Arithmetic: 8-bit Signed Integers (Fixed-point)**.
- **Memory: Block RAM (BRAM) for weights, Distributed RAM/LUTs for biases**.
- **Activation: ReLU (Rectified Linear Unit) implemented in RTL**.
- **Clock: Optimized for parallel execution using DSP48E1 slices**.

