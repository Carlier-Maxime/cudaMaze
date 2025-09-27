#include "random.cuh"

#include "array.cuh"

__global__ void kernelInitCurand(const size_t seed, curandState *states, const size_t size) {
    if (const auto id = d_getArray1DIndex(); id < size) curand_init(seed, id, 0, &states[id]);
}
