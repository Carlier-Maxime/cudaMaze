#pragma once
#include <cstdint>

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

#define HANDLE_ERROR(error) if (cudaError_t err = error; err != cudaSuccess) {std::cerr << "CudaError : " << cudaGetErrorString(err) << std::endl;}
#define GET_MAX_BLOCKS_1D(size) ((size / DEFAULT_THREADS_DIMS_1D.x) + ((size % DEFAULT_THREADS_DIMS_1D.x) ? 1 : 0))

template <typename TYPE>
__device__ void swap(TYPE& a, TYPE& b) noexcept {
    TYPE tmp = a;
    a = b;
    b = tmp;
}