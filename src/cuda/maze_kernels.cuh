#pragma once
#include "utils.cuh"

template <typename GRID_TYPE>
__global__ void kernelResetPairsAndCond(GRID_TYPE *pairs,  const size_t size, bool* cond) {
    const auto i = d_getArray1DIndex();
    if (i < size) pairs[i]=0;
    if (i == 0) cond[0] = false;
}

template <typename GRID_TYPE>
__device__ void dMazePairForBreakWall(
            GRID_TYPE *pairs, GRID_TYPE *ws, bool *vWall, bool *hWall,
            curandState *rng_states, const size_t ir,
            const size_t height, const size_t width, const size_t y1, const size_t x1) {
    uint32_t i1 = y1 * width + x1;
    if (y1 >= height || x1 >= width) return;
    const auto d = curand(rng_states+ir) % 4;
    const auto ay = (d&1) == 0 ? (d == 0 ? -1 : 1) : 0;
    const auto ax = (d&1) == 0 ? 0 : d == 1 ? 1 : -1;
    const uint16_t y2 = y1 + ay, x2 = x1 + ax;
    uint32_t i2 = y2 * width + x2;
    if (y2 >= height || x2 >= width) return;
    if (ws[i2] == ws[i1]) return;
    if (ws[i2] > ws[i1]) swap(i1, i2);
    if (ws[i2] < ws[i1] && atomicCAS(pairs+ws[i1]-1, 0, ws[i2]) != 0) return;
    bool* wall;
    size_t wIndex;
    if (ay == 0) {
        wall = vWall;
        wIndex = y1*(width-1)+(x1-(ax<0));
    } else {
        wall = hWall;
        wIndex = (y1-(ay<0))*width+x1;
    }
    wall[wIndex] = false;
}

template <typename GRID_TYPE>
__global__ void kernelMazePairForBreakWall(GRID_TYPE *pairs, GRID_TYPE *ws, bool *vWall, bool *hWall, curandState *rng_states, const size_t height, const size_t width) {
    const auto w = dCeilDiv<size_t>(width, gridDim.x * blockDim.x);
    const auto h = dCeilDiv<size_t>(height, gridDim.y * blockDim.y);
    const auto [y, x, ir] = d_getArray2DIndices(gridDim.x * blockDim.x);
    for (auto i=0; i<h; ++i) {
        for (auto j=0; j<w; ++j) {
            const auto y1 = y*h+i, x1 = x*w+j;
            dMazePairForBreakWall(pairs, ws, vWall, hWall, rng_states, ir, height, width, y1, x1);
        }
    }
}

template<typename GRID_TYPE>
__global__ void kernelMazeApplyPairs(GRID_TYPE *pairs, GRID_TYPE *ws, const size_t height, const size_t width, bool *cond_ret) {
    const auto [y, x, i] = d_getArray2DIndices(width);
    if (y >= height || x >= width) return;
    auto val = ws[i];
    while (pairs[val - 1] != 0) val = pairs[val - 1];
    ws[i] = val;
    if (val != 1) *cond_ret = true;
}

template <typename GRID_TYPE>
__global__ void kernelOneInRealSize(GRID_TYPE *ws, const size_t size, size_t newIndexForOne) {
    const auto i = d_getArray1DIndex();
    if (i >= size || ws[i] != 1) return;
    swap(ws[i], ws[newIndexForOne]);
}
