#pragma once
#include <cstdint>

#include "../utils/math_utils.hpp"

const cudaDeviceProp DEVICE_PROP = [] {
    cudaDeviceProp deviceProp{};
    cudaGetDeviceProperties(&deviceProp, 0);
    return deviceProp;
}();
const auto DEFAULT_THREADS_DIMS_1D = dim3(DEVICE_PROP.maxThreadsPerBlock, 1, 1);
const auto DEFAULT_THREADS_DIMS_2D = [] {
    auto td = dim3(static_cast<uint16_t>(sqrtl(DEVICE_PROP.maxThreadsPerBlock)));
    td.y = td.x;
    return td;
}();
const auto MAX_SIMULTANEOUS_THREADS = DEVICE_PROP.maxThreadsPerMultiProcessor * DEVICE_PROP.multiProcessorCount;

#define HANDLE_ERROR(error) if (cudaError_t err = error; err != cudaSuccess) {std::cerr << "CudaError : " << cudaGetErrorString(err) << std::endl;}
#define GET_MAX_BLOCKS_1D(size) ceilDiv<uint32_t>(size, DEFAULT_THREADS_DIMS_1D.x)
#define GET_MAX_BLOCKS_2D(height, width) dim3(\
    ceilDiv<uint32_t>(width, DEFAULT_THREADS_DIMS_2D.x),\
    ceilDiv<uint32_t>(height, DEFAULT_THREADS_DIMS_2D.y),\
    1)
template <typename TYPE>
__device__ void swap(TYPE& a, TYPE& b) noexcept {
    TYPE tmp = a;
    a = b;
    b = tmp;
}

template <typename T>
__device__ T dCeilDiv(T a, T b) {
    return (a + b - 1) / b;
}