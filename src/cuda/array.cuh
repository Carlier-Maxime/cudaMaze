#pragma once

template <typename GRID_TYPE>
__global__ void kernelInitArrayRange1D(GRID_TYPE *grid, const size_t size, GRID_TYPE start, GRID_TYPE increment) {
    const auto i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < size) grid[i] = start + i*increment;
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