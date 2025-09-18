#pragma once
#include <vector>
#include <iostream>

__device__ __forceinline__ size_t d_getArray1DIndex() {
    return blockIdx.x * blockDim.x + threadIdx.x;
}

struct Array2DIndices {
    const size_t y, x, i;
};

__device__ __forceinline__ Array2DIndices d_getArray2DIndices(const size_t width) {
    const auto y = blockIdx.y * blockDim.y + threadIdx.y;
    const auto x = blockIdx.x * blockDim.x + threadIdx.x;
    const auto i = y * width + x;
    return {y, x, i};
}

template <typename GRID_TYPE>
__global__ void kernelInitArrayRange1D(GRID_TYPE *grid, const size_t size, GRID_TYPE start, GRID_TYPE increment) {
    const auto i = d_getArray1DIndex();
    if (i < size) grid[i] = start + i*increment;
}

template <typename GRID_TYPE>
__global__ void kernelInitArray1D(GRID_TYPE *grid, const size_t size, const GRID_TYPE value) {
    const auto i = d_getArray1DIndex();
    if (i < size) grid[i] = value;
}

template <typename GRID_TYPE>
__host__ auto cudaArrayToHost(GRID_TYPE *d_arr, size_t size) {
    auto arr = std::vector<GRID_TYPE>(size);
    cudaMemcpy(arr.data(), d_arr, sizeof(GRID_TYPE) * size, cudaMemcpyDefault);
    return arr;
}

template <typename GRID_TYPE>
__host__ void showCudaArrayInHost(GRID_TYPE *d_arr, size_t size) {
    auto arr = cudaArrayToHost(d_arr, size);
    for ( const auto e : arr) std::cout << e << ' ';
    std::cout << std::endl << std::endl;
}
