def export_for_fpga(model_path):
    model = SimpleMLP()
    model.load_state_dict(torch.load(model_path))

    # Calculate Unified Scale Factor
    max_fc1 = model.fc1.weight.abs().max().item()
    max_fc2 = model.fc2.weight.abs().max().item()
    scale = 127 / max(max_fc1, max_fc2)
    print(f"Unified Scale Factor: {scale}")

    state_dict = model.state_dict()
    for name, param in state_dict.items():
        # Quantize to int8
        quantized = np.clip(np.round(param.numpy() * scale), -128, 127).astype(np.int8)

        # 1. Save as TXT (for general reference)
        base_name = name.replace('.', '_')
        np.savetxt(f"{base_name}.txt", quantized.flatten(), fmt='%d')

        # 2. Save Weights and Biases as COE (for Xilinx BRAM)
        create_coe_file(quantized, f"{base_name}.coe")

        # 3. Optional: Save Biases as a Verilog Header (for easy logic integration)
        if 'bias' in name:
            with open(f"{base_name}.vh", "w") as f:
                f.write(f"// Quantized Biases for {name}\n")
                for i, val in enumerate(quantized.flatten()):
                    # Format as 8-bit hex for Verilog
                    f.write(f"parameter BIAS_{i} = 8'h{val & 0xFF:02x};\n")

    print("All parameters (weights and biases) exported as COE and TXT.")
export_for_fpga("mnist_weights.pth")