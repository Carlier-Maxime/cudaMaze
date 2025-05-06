#include "random.cuh"

__global__ void kernelInitCurand(const size_t seed, curandState *states, const size_t size) {
    if (const auto id = blockIdx.x * blockDim.x + threadIdx.x; id < size) curand_init(seed, id, 0, &states[id]);
}

__global__ void kernelRandomArray(uint32_t *arr, curandState *states, const size_t size) {
    if (const auto i = blockIdx.x * blockDim.x + threadIdx.x; i < size) arr[i] = curand(states+i);
}