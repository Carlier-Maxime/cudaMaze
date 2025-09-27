#pragma once

#include "maze_kernels.cuh"
#include "../Maze.h"

template <typename GRID_TYPE>
std::vector<GRID_TYPE> MazeGridBuilder<GRID_TYPE, BackendCUDA>::build(const Maze& maze) const {
    bool *d_vWall, *d_hWall;
    HANDLE_ERROR(cudaMalloc(&d_vWall, sizeof(bool) * maze.getVWallSize()));
    HANDLE_ERROR(cudaMalloc(&d_hWall, sizeof(bool) * maze.getHWallSize()));
    cudaMemcpy(d_vWall, maze.verticalWall, sizeof(char) * maze.getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(d_hWall, maze.horizontalWall, sizeof(char) * maze.getHWallSize(), cudaMemcpyDefault);
    char* d_grid;
    const size_t h = maze.getGridHeight(this->wallVerticalSize), w = maze.getGridWidth(this->wallHorizontalSize);
    HANDLE_ERROR(cudaMalloc(&d_grid, sizeof(char) * h * w));
    kernelMazeToGrid<<<GET_MAX_BLOCKS_2D(h, w), DEFAULT_THREADS_DIMS_2D>>>(
        d_grid, h, w, d_vWall, d_hWall, this->wallVerticalSize, this->wallHorizontalSize,
        this->pathValue, this->wallAngleValue, this->wallVerticalValue, this->wallHorizontalValue, maze.getWidth());
    std::vector<char> grid(h * w);
    cudaDeviceSynchronize();
    HANDLE_ERROR(cudaFree(d_hWall));
    HANDLE_ERROR(cudaFree(d_vWall));
    cudaMemcpy(grid.data(), d_grid, sizeof(char) * h * w, cudaMemcpyDefault);
    HANDLE_ERROR(cudaFree(d_grid));
    return grid;
}