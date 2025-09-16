#pragma once
#include "utils.cuh"

template <typename GRID_TYPE>
__global__ void kernelInitMazeGrid(GRID_TYPE *maze, GRID_TYPE *ids, const size_t height, const size_t width) {
    const auto [y, x, i] = d_getArray2DIndices(width);
    if (y < height && x < width) maze[i] = y&1 || x&1 ? 0 : ids[(y>>1) * (width>>1) + (x>>1)];
}

template <typename GRID_TYPE>
__global__ void kernelResetPairsAndCond(GRID_TYPE *pairs,  const size_t size, bool* cond) {
    const auto i = d_getArray1DIndex();
    if (i < size) pairs[i]=0;
    if (i == 0) cond[0] = false;
}

template <typename GRID_TYPE>
__global__ void kernelMazePairForBreakWall(GRID_TYPE *maze, curandState *rng_states, GRID_TYPE *pairs, const size_t height, const size_t width) {
    const auto [y, x, i] = d_getArray2DIndices(width);
    if (y >= height || x >= width || maze[i]==0) return;
    const auto d = curand(rng_states+i) % 4;
    const auto ay = (d&1) == 0 ? (d == 0 ? -1 : 1) : 0;
    const auto ax = (d&1) == 0 ? 0 : d == 1 ? 1 : -1;
    const uint16_t y2 = y + ay, x2 = x + ax;
    uint32_t i2 = y2 * width + x2;
    if (y2 >= height || x2 >= width || maze[i2] != 0) return;
    const uint16_t y3 = y2 + ay, x3 = x2 + ax;
    uint32_t i3 = y3 * width + x3;
    if (y3 >= height || x3 >= width || maze[i3] == 0 || maze[i3] >= maze[i] || atomicCAS(pairs+maze[i]-1, 0, maze[i3]) != 0) return;
    maze[i2] = maze[i];
}

template<typename GRID_TYPE>
__global__ void kernelMazeApplyPairs(GRID_TYPE *maze, GRID_TYPE *pairs, const size_t height, const size_t width, bool *cond_ret) {
    const auto [y, x, i] = d_getArray2DIndices(width);
    if (y >= height || x >= width || maze[i] == 0) return;
    auto val = maze[i];
    while (pairs[val - 1] != 0) val = pairs[val - 1];
    maze[i] = val;
    if (val != 1) *cond_ret = true;
}

template <typename GRID_TYPE>
__global__ void kernelOneInRealPairsSize(GRID_TYPE *pairs, const size_t size, size_t newIndexForOne) {
    const auto i = d_getArray1DIndex();
    if (i >= size || pairs[i] != 1) return;
    swap(pairs[i], pairs[newIndexForOne]);
}

template <typename MAZE_SOURCE_TYPE>
__global__ void kernelCastMazeToCharArray(MAZE_SOURCE_TYPE *source_maze, char *target_maze, const size_t size, const size_t width) {
    const auto [y, x, i] = d_getArray2DIndices(width);
    if (i < size) target_maze[i] = source_maze[i] == 0 ? 0 : 255;
}