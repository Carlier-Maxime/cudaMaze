#pragma once
#include "utils.cuh"

template <typename GRID_TYPE>
__global__ void kernelBitonicSortStep(GRID_TYPE *arr, GRID_TYPE *keys, const uint32_t size, const uint32_t j) {
    const auto idx1 = blockIdx.x * blockDim.x + threadIdx.x;
    const auto idx2 = idx1 ^ j;
    if (idx2 < size && idx2 > idx1) {
        if ((idx1 & j) == 0) {
            if (keys[idx1] > keys[idx2]) {
                swap(arr[idx1], arr[idx2]);
                swap(keys[idx1], keys[idx2]);
            }
        } else {
            if (keys[idx1] < keys[idx2]) {
                swap(arr[idx1], arr[idx2]);
                swap(keys[idx1], keys[idx2]);
            }
        }
    }
}

template <typename GRID_TYPE>
__host__ void cudaBitonicSort(GRID_TYPE *arr, GRID_TYPE *keys, const uint32_t size) {
    for (uint32_t j = 2; j < size; j<<=1) {
        for (uint32_t k = j>>1; k > 0; k>>=1) {
            kernelBitonicSortStep<GRID_TYPE><<<GET_MAX_BLOCKS_1D(size), DEFAULT_THREADS_DIMS_1D>>>(arr, keys, size, j);
            cudaDeviceSynchronize();
        }
    }
}