import torch
import numpy as np
import matplotlib.pyplot as plt
from model import SimpleMLP

def predict_raw_hex(hex_file, model_path):
    pixels = []
    with open(hex_file, 'r') as f:
        for line in f:
            pixels.append(int(line.strip(), 16))

    pixel_array = np.array(pixels, dtype=np.float32).reshape(28, 28)
    normalized_pixels = pixel_array / 255.0
    input_tensor = torch.from_numpy(normalized_pixels).unsqueeze(0).unsqueeze(0)

    model = SimpleMLP()
    model.load_state_dict(torch.load(model_path))
    model.eval()

    with torch.no_grad():
        output = model(input_tensor)
        prediction = output.argmax(dim=1).item()

    plt.imshow(pixel_array, cmap='gray')
    plt.title(f"File: {hex_file} | Prediction: {prediction}")
    plt.show()

if __name__ == "__main__":
    # Example usage:
    # predict_raw_hex("digit6.hex", "mnist_weights.pth")
    pass