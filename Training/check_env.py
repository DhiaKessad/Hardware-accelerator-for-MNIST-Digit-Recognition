import torch
import torchvision
import numpy as np
import PIL
import matplotlib
import sys

def check_versions():
    print("--- MNIST to FPGA Environment Check ---")
    print(f"Python version:      {sys.version.split()[0]}")
    print(f"PyTorch version:     {torch.__version__}")
    print(f"Torchvision version: {torchvision.__version__}")
    print(f"NumPy version:       {np.__version__}")
    print(f"Pillow version:      {PIL.__version__}")
    print(f"Matplotlib version:  {matplotlib.__version__}")
    print(f"CUDA (GPU) support:  {torch.cuda.is_available()}")
    print("-" * 40)

if __name__ == "__main__":
    check_versions()