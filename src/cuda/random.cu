#include "random.cuh"

#include "array.cuh"

__global__ void kernelInitCurand(const size_t seed, curandState *states, const size_t size) {
    if (const auto id = d_getArray1DIndex(); id < size) curand_init(seed, id, 0, &states[id]);
}

__global__ void kernelRandomArray(uint32_t *arr, curandState *states, const size_t size) {
    const auto id = d_getArray1DIndex();
    const auto elements_per_thread = dCeilDiv<uint32_t>(size, (gridDim.x * blockDim.x));
    for (int i = 0; i < elements_per_thread; ++i) {
        if (const auto index = id * elements_per_thread + i; index < size)
            arr[index] = curand(states+id);
    }
}