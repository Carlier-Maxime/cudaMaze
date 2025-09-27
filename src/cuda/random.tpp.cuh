#pragma once
#include "array.cuh"

template <UnsignedIntegral U>
__global__ void kernelRandomArray(U *arr, curandState *states, const size_t size) {
    const auto id = d_getArray1DIndex();
    const auto elements_per_thread = dCeilDiv<U>(size, (gridDim.x * blockDim.x));
    for (int i = 0; i < elements_per_thread; ++i) {
        if (const auto index = id * elements_per_thread + i; index < size)
            arr[index] = curand(states+id);
    }
}
