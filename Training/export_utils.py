import torch
import numpy as np

def create_coe_file(input_array, filename, rad=16):
    flat_data = input_array.flatten()
    with open(filename, 'w') as f:
        f.write(f"memory_initialization_radix={rad};\n")
        f.write("memory_initialization_vector=\n")
        for i, val in enumerate(flat_data):
            hex_val = format(val & 0xFF, '02x')
            f.write(f"{hex_val},\n" if i < len(flat_data) - 1 else f"{hex_val};")

def export_for_fpga(model_path):
    model = SimpleMLP()
    model.load_state_dict(torch.load(model_path))
    
    # Calculate Unified Scale Factor
    max_fc1 = model.fc1.weight.abs().max().item()
    max_fc2 = model.fc2.weight.abs().max().item()
    scale = 127 / max(max_fc1, max_fc2)
    
    state_dict = model.state_dict()
    for name, param in state_dict.items():
        quantized = np.clip(np.round(param.numpy() * scale), -128, 127).astype(np.int8)
        base_name = name.replace('.', '_')
        
        # Save TXT and COE
        np.savetxt(f"{base_name}.txt", quantized.flatten(), fmt='%d')
        create_coe_file(quantized, f"{base_name}.coe")
        
        # Save Biases as Verilog Header
        if 'bias' in name:
            with open(f"{base_name}.vh", "w") as f:
                f.write(f"// Quantized Biases for {name}\n")
                for i, val in enumerate(quantized.flatten()):
                    f.write(f"parameter BIAS_{i} = 8'h{val & 0xFF:02x};\n")

    print(f"Success! Unified scale ({scale:.2f}) applied to weights and biases.")

if __name__ == "__main__":
    export_for_fpga("mnist_weights.pth")
