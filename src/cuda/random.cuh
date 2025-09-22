#pragma once
#include <cstdint>
#include <curand_kernel.h>

#include "utils.cuh"
#include "../utils/math_utils.hpp"

const auto RECOMMENDED_CURAND_BLOCK_1D = ceilDiv(MAX_SIMULTANEOUS_THREADS, DEVICE_PROP.maxThreadsPerBlock);
const auto RECOMMENDED_CURAND_STATE_COUNT = RECOMMENDED_CURAND_BLOCK_1D * DEVICE_PROP.maxThreadsPerBlock;
const auto RECOMMENDED_CURAND_BLOCK_2D = dim3(RECOMMENDED_CURAND_BLOCK_1D, 1, 1);

__global__ void kernelInitCurand(size_t seed, curandState *states, size_t size);
__global__ void kernelRandomArray(uint32_t *arr, curandState *states, size_t size);
