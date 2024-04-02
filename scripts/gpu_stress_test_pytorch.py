import torch

# Check if GPU is available
if torch.cuda.is_available():
    device = torch.device('cuda')
    print('GPU is available')
else:
    device = torch.device('cpu')
    print('GPU is not available')

for i in range(500):
    # Define the size of the tensors for the stress test
    tensor_size = (10000, 10000)

    # Create large tensors on the GPU
    a = torch.randn(tensor_size, device=device)
    b = torch.randn(tensor_size, device=device)

    # Perform heavy computations on the GPU
    result = torch.matmul(a, b)

    # Move result back to CPU for printing (if needed)
    result_cpu = result.cpu()

    print('Stress test completed successfully!')
