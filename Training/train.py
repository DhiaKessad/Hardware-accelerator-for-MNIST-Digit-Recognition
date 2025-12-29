import torch
import torch.optim as optim
from torchvision import datasets, transforms
from model import SimpleMLP

def train_model(epochs=2):
    model = SimpleMLP()
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.CrossEntropyLoss()

    train_loader = torch.utils.data.DataLoader(
        datasets.MNIST('./data', train=True, download=True,
                       transform=transforms.ToTensor()), batch_size=64)

    model.train()
    for epoch in range(1, epochs + 1):
        for batch_idx, (data, target) in enumerate(train_loader):
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
        print(f"Epoch {epoch} complete.")

    torch.save(model.state_dict(), "mnist_weights.pth")
    print("Saved: mnist_weights.pth")

if __name__ == "__main__":
    train_model()