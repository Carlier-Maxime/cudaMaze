#pragma once

#include "array.cuh"
#include "random.cuh"
#include "sort.cuh"
#include "maze_kernels.cuh"
#include "../Maze.h"
#include "../utils/debug.hpp"

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::checkParam() {
    MazeBuilderBase::checkParam();
    if (static_cast<size_t>(std::numeric_limits<GRID_TYPE>::max()) < roundToNextPowerOfTwo(maze->getSize())) {
        throw std::runtime_error(
            "MazeBuilder::checkParam() failed: GRID_TYPE is not large enough to store height x width");
    }
}

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::allocData() {
    ids_size = roundToNextPowerOfTwo(maze->getSize());
    rand_size = RECOMMENDED_CURAND_STATE_COUNT;
    HANDLE_ERROR(cudaMalloc(&d_vWall, sizeof(bool) * maze->getVWallSize()));
    HANDLE_ERROR(cudaMalloc(&d_hWall, sizeof(bool) * maze->getHWallSize()));
    HANDLE_ERROR(cudaMalloc(&d_rngStates, sizeof(curandState) * rand_size));
    HANDLE_ERROR(cudaMalloc(&d_pairs, sizeof(GRID_TYPE) * ids_size));
    HANDLE_ERROR(cudaMalloc(&d_ws, sizeof(GRID_TYPE) * ids_size));
    HANDLE_ERROR(cudaMalloc(&d_cond, sizeof(bool) * 1));
}

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::initData() {
    kernelInitCurand<<<GET_MAX_BLOCKS_1D(rand_size), DEFAULT_THREADS_DIMS_1D>>>(maze->getSeed(), d_rngStates, rand_size);
    kernelInitArrayRange1D<GRID_TYPE><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_ws, ids_size, 1, 1);
    kernelInitArray1D<bool><<<GET_MAX_BLOCKS_1D(maze->getVWallSize()), DEFAULT_THREADS_DIMS_1D>>>(d_vWall, maze->getVWallSize(), true);
    kernelInitArray1D<bool><<<GET_MAX_BLOCKS_1D(maze->getHWallSize()), DEFAULT_THREADS_DIMS_1D>>>(d_hWall, maze->getHWallSize(), true);
    cudaDeviceSynchronize();
    kernelRandomArray<<<GET_MAX_BLOCKS_1D(rand_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, d_rngStates, ids_size);
    cudaDeviceSynchronize();
}

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::shuffleWeights() {
    cudaBitonicSort<GRID_TYPE>(d_ws, d_pairs, ids_size);
    const auto newIndexForOne = getIndexForOne();
    cudaDeviceSynchronize();
    kernelOneInRealSize<<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_ws, ids_size, newIndexForOne);
    cudaDeviceSynchronize();
}

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::breakWallsStep(bool& cond) {
    const auto h = maze->getHeight(), w = maze->getWidth();
    kernelResetPairsAndCond<GRID_TYPE><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, d_cond);
    cudaDeviceSynchronize();
    kernelMazePairForBreakWall<<<RECOMMENDED_CURAND_BLOCK_2D, DEFAULT_THREADS_DIMS_2D>>>(d_pairs, d_ws, d_vWall, d_hWall, d_rngStates, h, w);
    cudaDeviceSynchronize();
    kernelMazeApplyPairs<<<GET_MAX_BLOCKS_2D(h, w), DEFAULT_THREADS_DIMS_2D>>>(d_pairs, d_ws, h, w, d_cond);
    cudaDeviceSynchronize();
    cudaMemcpy(&cond, d_cond, sizeof(bool), cudaMemcpyDefault);
}

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::transferResult() {
    cudaMemcpy(maze->verticalWall, d_vWall, sizeof(char) * maze->getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(maze->horizontalWall, d_hWall, sizeof(char) * maze->getHWallSize(), cudaMemcpyDefault);
}

template <UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::freeData() {
    HANDLE_ERROR(cudaFree(d_rngStates));
    HANDLE_ERROR(cudaFree(d_pairs));
    HANDLE_ERROR(cudaFree(d_ws));
    HANDLE_ERROR(cudaFree(d_cond));
    HANDLE_ERROR(cudaFree(d_hWall));
    HANDLE_ERROR(cudaFree(d_vWall));
}

template<UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::debugPairs() {
    auto arr = cudaArrayToHost(d_pairs, roundToNextPowerOfTwo(maze->getSize()));
    for (auto i=0; i<maze->getSize(); ++i) {
        if (arr[i] == 0) continue;
        std::cout << i+1 << " => " << arr[i] << std::endl;
    }
}

template<UnsignedIntegral GRID_TYPE>
void MazeBuilder<GRID_TYPE, BackendCUDA>::debugWeights() {
    auto arr = cudaArrayToHost(d_ws, maze->getSize());
    debugArray2D(arr, maze->getWidth(), maze->getHeight(), roundToNextPowerOfTwo(maze->getSize()));
}
