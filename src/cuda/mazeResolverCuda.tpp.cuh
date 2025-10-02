#pragma once
#include <ostream>

#include "utils.cuh"
#include "array.cuh"
#include "maze_kernels.cuh"

template <UnsignedIntegral GRID_TYPE>
void MazeResolver<GRID_TYPE, BackendCUDA>::resolve(const Maze& maze, MazeSolution<GRID_TYPE>& solution) {
    HANDLE_ERROR(cudaMalloc(&ws, sizeof(GRID_TYPE) * maze.getSize()));
    kernelInitArray1D<GRID_TYPE><<<GET_MAX_BLOCKS_1D(maze.getSize()), DEFAULT_THREADS_DIMS_1D>>>(ws, maze.getSize(), 0);
    HANDLE_ERROR(cudaMalloc(&vWall, sizeof(bool) * maze.getVWallSize()));
    HANDLE_ERROR(cudaMalloc(&hWall, sizeof(bool) * maze.getHWallSize()));
    cudaMemcpy(vWall, maze.verticalWall, sizeof(char) * maze.getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(hWall, maze.horizontalWall, sizeof(char) * maze.getHWallSize(), cudaMemcpyDefault);
    HANDLE_ERROR(cudaMalloc(&cond, sizeof(bool)));
    bool h_cond = true;
    cudaDeviceSynchronize();
    GRID_TYPE maxDistance = 1;
    cudaMemcpy(ws+solution.end.y*maze.getWidth()+solution.end.x, &maxDistance, sizeof(GRID_TYPE), cudaMemcpyDefault);
    while (h_cond) {
        h_cond = false;
        cudaMemcpy(cond, &h_cond, sizeof(bool), cudaMemcpyDefault);
        kernelMazeBFS<GRID_TYPE><<<GET_MAX_BLOCKS_2D(maze.getHeight(), maze.getWidth()), DEFAULT_THREADS_DIMS_2D>>>(
            ws, maze.getHeight(), maze.getWidth(), vWall, hWall,
            solution.start, solution.stopWhenPathFound, cond, maxDistance
        );
        cudaDeviceSynchronize();
        cudaMemcpy(&h_cond, cond, sizeof(bool), cudaMemcpyDefault);
        ++maxDistance;
    }
    solution.maxDistance = maxDistance;
    HANDLE_ERROR(cudaFree(cond));
    HANDLE_ERROR(cudaFree(hWall));
    HANDLE_ERROR(cudaFree(vWall));
    solution.distanceToEnd.resize(maze.getSize());
    cudaMemcpy(solution.distanceToEnd.data(), ws, sizeof(GRID_TYPE) * maze.getSize(), cudaMemcpyDefault);
    HANDLE_ERROR(cudaFree(ws));
}
