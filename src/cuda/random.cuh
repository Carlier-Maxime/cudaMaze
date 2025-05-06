#pragma once
#include <curand_kernel.h>

__global__ void kernelInitCurand(size_t seed, curandState *states, size_t size);
__global__ void kernelRandomArray(uint32_t *arr, curandState *states, size_t size);
