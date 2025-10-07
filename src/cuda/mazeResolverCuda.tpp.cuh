#pragma once
#include <ostream>

#include "utils.cuh"
#include "array.cuh"
#include "maze_kernels.cuh"

template <UnsignedIntegral GRID_TYPE>
void MazeResolver<GRID_TYPE, BackendCUDA>::resolve(const Maze& maze, MazeSolution<GRID_TYPE>& solution) {
    HANDLE_ERROR(cudaMalloc(&ws, sizeof(GRID_TYPE) * maze.getSize()));
    kernelInitArray1D<GRID_TYPE><<<GET_MAX_BLOCKS_1D(maze.getSize()), DEFAULT_THREADS_DIMS_1D>>>(ws, maze.getSize(), 0);
    const auto h = maze.getHeight(), w = maze.getWidth();
    const size_t indicesSize = min(h, w)*10;
    HANDLE_ERROR(cudaMalloc(&indices, sizeof(Position<GRID_TYPE>) * indicesSize));
    kernelInitArray1D<Position<GRID_TYPE>><<<GET_MAX_BLOCKS_1D(indicesSize), DEFAULT_THREADS_DIMS_1D>>>(indices, indicesSize, {w, h});
    auto h_indices = std::vector<Position<GRID_TYPE>>(indicesSize);
    HANDLE_ERROR(cudaMalloc(&vWall, sizeof(bool) * maze.getVWallSize()));
    HANDLE_ERROR(cudaMalloc(&hWall, sizeof(bool) * maze.getHWallSize()));
    cudaMemcpy(vWall, maze.verticalWall, sizeof(char) * maze.getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(hWall, maze.horizontalWall, sizeof(char) * maze.getHWallSize(), cudaMemcpyDefault);
    HANDLE_ERROR(cudaMalloc(&cond, sizeof(bool)));
    bool h_cond = true;
    cudaDeviceSynchronize();
    GRID_TYPE maxDistance = 0;
    cudaMemcpy(indices, &solution.end, sizeof(Position<GRID_TYPE>), cudaMemcpyDefault);
    size_t nbThreads = 1;
    while (h_cond) {
        h_cond = false;
        ++maxDistance;
        cudaMemcpy(cond, &h_cond, sizeof(bool), cudaMemcpyDefault);
        kernelMazeBFS<GRID_TYPE><<<GET_MAX_BLOCKS_1D(nbThreads), DEFAULT_THREADS_DIMS_1D>>>(
            ws, indices, indicesSize, h, w, vWall, hWall, cond, maxDistance
        );
        cudaDeviceSynchronize();
        cudaMemcpy(&h_cond, cond, sizeof(bool), cudaMemcpyDefault);
        GRID_TYPE startWeight;
        cudaMemcpy(&startWeight, &ws[solution.start.y * w + solution.start.x], sizeof(GRID_TYPE), cudaMemcpyDefault);
        h_cond = h_cond && (!solution.stopWhenPathFound || startWeight == 0);
        cudaMemcpy(h_indices.data(), indices, sizeof(Position<GRID_TYPE>) * indicesSize, cudaMemcpyDefault);
        size_t index = 0;
        for (size_t i = 0; i < indicesSize; i+=5) {
            if (i>=nbThreads*5) break;
            for (size_t j = 1; j < 5; ++j) {
                if (i+j>=indicesSize) break;
                const auto [x, y] = h_indices[i+j];
                if (x >= w || y >= h) continue;
                h_indices[index] = {x, y};
                h_indices[i+j] = {w, h};
                index += 5;
            }
            if (!h_cond) break;
        }
        cudaMemcpy(indices, h_indices.data(), sizeof(Position<GRID_TYPE>) * indicesSize, cudaMemcpyDefault);
        nbThreads = ceilDiv<size_t>(index,5);
    }
    solution.maxDistance = maxDistance;
    HANDLE_ERROR(cudaFree(cond));
    HANDLE_ERROR(cudaFree(indices));
    HANDLE_ERROR(cudaFree(hWall));
    HANDLE_ERROR(cudaFree(vWall));
    solution.distanceToEnd.resize(maze.getSize());
    cudaMemcpy(solution.distanceToEnd.data(), ws, sizeof(GRID_TYPE) * maze.getSize(), cudaMemcpyDefault);
    HANDLE_ERROR(cudaFree(ws));
}
