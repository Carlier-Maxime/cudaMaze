#pragma once

#include "maze_kernels.cuh"
#include "../Maze.h"

template <UnsignedIntegral U, typename GRID_TYPE>
std::vector<GRID_TYPE> MazeGridBuilder<U, GRID_TYPE, BackendCUDA>::build(const Maze& maze) const {
    bool *d_vWall, *d_hWall;
    HANDLE_ERROR(cudaMalloc(&d_vWall, sizeof(bool) * maze.getVWallSize()));
    HANDLE_ERROR(cudaMalloc(&d_hWall, sizeof(bool) * maze.getHWallSize()));
    cudaMemcpy(d_vWall, maze.verticalWall, sizeof(char) * maze.getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(d_hWall, maze.horizontalWall, sizeof(char) * maze.getHWallSize(), cudaMemcpyDefault);
    char* d_grid;
    const size_t h = maze.getGridHeight(this->wallVerticalSize), w = maze.getGridWidth(this->wallHorizontalSize);
    HANDLE_ERROR(cudaMalloc(&d_grid, sizeof(char) * h * w));
    GRID_TYPE* d_pathValues;
    const auto PathValuesSizeOctet = sizeof(GRID_TYPE) * this->pathValues.size();
    HANDLE_ERROR(cudaMalloc(&d_pathValues, PathValuesSizeOctet));
    cudaMemcpy(d_pathValues, this->pathValues.data(), PathValuesSizeOctet, cudaMemcpyDefault);
    U* d_pathValueIndices = nullptr;
    if (!this->pathValueIndices.empty()) {
        const auto PathValueIndicesSizeOctet = sizeof(U) * this->pathValueIndices.size();
        HANDLE_ERROR(cudaMalloc(&d_pathValueIndices, PathValueIndicesSizeOctet));
        cudaMemcpy(d_pathValueIndices, this->pathValueIndices.data(), PathValueIndicesSizeOctet, cudaMemcpyDefault);
    }
    kernelMazeToGrid<size_t, GRID_TYPE><<<GET_MAX_BLOCKS_2D(h, w), DEFAULT_THREADS_DIMS_2D>>>(
        d_grid, h, w, d_vWall, d_hWall, this->wallVerticalSize,
        this->wallHorizontalSize, d_pathValueIndices, d_pathValues, this->pathValues.size()-1,
        this->wallAngleValue, this->wallVerticalValue, this->wallHorizontalValue, maze.getWidth());
    std::vector<char> grid(h * w);
    cudaDeviceSynchronize();
    HANDLE_ERROR(cudaFree(d_pathValueIndices));
    HANDLE_ERROR(cudaFree(d_pathValues));
    HANDLE_ERROR(cudaFree(d_hWall));
    HANDLE_ERROR(cudaFree(d_vWall));
    cudaMemcpy(grid.data(), d_grid, sizeof(char) * h * w, cudaMemcpyDefault);
    HANDLE_ERROR(cudaFree(d_grid));
    return grid;
}