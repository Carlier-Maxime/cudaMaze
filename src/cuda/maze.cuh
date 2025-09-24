#pragma once


#include <curand_kernel.h>
#include <ostream>
#include <set>

#include "../Maze.h"
#include "../utils/chronometer.hpp"
#include "../utils/math_utils.hpp"
#include "random.cuh"
#include "utils.cuh"
#include "sort.cuh"
#include "array.cuh"
#include "maze_kernels.cuh"

template <typename GRID_TYPE>
class MazeCuda : public Maze {
    auto allocDataGPU() {
        GRID_TYPE *d_pairs, *d_ws;
        curandState *d_rngStates;
        bool *d_vWall, *d_hWall, *d_cond;
        const auto ids_size = roundToNextPowerOfTwo(getSize());
        const auto rand_size = RECOMMENDED_CURAND_STATE_COUNT;
        HANDLE_ERROR(cudaMalloc(&d_vWall, sizeof(bool) * verticalWall.size()));
        HANDLE_ERROR(cudaMalloc(&d_hWall, sizeof(bool) * horizontalWall.size()));
        HANDLE_ERROR(cudaMalloc(&d_rngStates, sizeof(curandState) * rand_size));
        HANDLE_ERROR(cudaMalloc(&d_pairs, sizeof(GRID_TYPE) * ids_size));
        HANDLE_ERROR(cudaMalloc(&d_ws, sizeof(GRID_TYPE) * ids_size));
        HANDLE_ERROR(cudaMalloc(&d_cond, sizeof(bool) * 1));
        return std::make_tuple(d_vWall, d_hWall, d_rngStates, d_pairs, d_ws, d_cond);
    }

    void moveWallToCPU(const bool* d_vWall, const bool* d_hWall);
    void debugWeights(GRID_TYPE* ws);
    void debugPairs(GRID_TYPE* pairs);

public:
    MazeCuda(const uint16_t height_, const uint16_t width_, const size_t seed_): MazeCuda(height_, width_, seed_, false){}
    MazeCuda(const uint16_t height_, const uint16_t width_, const bool verbose): MazeCuda(height_, width_, time(nullptr), verbose){}
    MazeCuda(const uint16_t height_, const uint16_t width_): MazeCuda(height_, width_, false){}
    MazeCuda(const uint16_t height_, const uint16_t width_, const size_t seed_, const bool verbose) : Maze(height_, width_, seed_, verbose) {
        auto chronoAll = Chronometer(), chrono = Chronometer();
        const auto height = getHeight(), width = getWidth();
        const uint32_t pairs_size_real_used = getSize();
        const uint32_t ids_size = roundToNextPowerOfTwo(pairs_size_real_used);
        const auto rand_size = RECOMMENDED_CURAND_STATE_COUNT;
        auto [d_vWall, d_hWall, d_rngStates, d_pairs, d_ws, d_cond] = allocDataGPU();
        if (verbose) {
            std::cout << "allocate data GPU, complete in : " << chrono << std::endl;
            chrono.reset();
        }
        kernelInitCurand<<<GET_MAX_BLOCKS_1D(rand_size), DEFAULT_THREADS_DIMS_1D>>>(getSeed(), d_rngStates, rand_size);
        kernelInitArrayRange1D<uint32_t><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_ws, ids_size, 1, 1);
        kernelInitArray1D<bool><<<GET_MAX_BLOCKS_1D(verticalWall.size()), DEFAULT_THREADS_DIMS_1D>>>(d_vWall, verticalWall.size(), true);
        kernelInitArray1D<bool><<<GET_MAX_BLOCKS_1D(horizontalWall.size()), DEFAULT_THREADS_DIMS_1D>>>(d_hWall, horizontalWall.size(), true);
        cudaDeviceSynchronize();
        kernelRandomArray<<<GET_MAX_BLOCKS_1D(rand_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, d_rngStates, ids_size);
        cudaDeviceSynchronize();
        if (verbose) {
            std::cout << "init intermediate data, complete in : " << chrono << std::endl;
            chrono.reset();
        }
        cudaBitonicSort<uint32_t>(d_ws, d_pairs, ids_size);
        const auto newIndexForOne = getIndexForOne();
        cudaDeviceSynchronize();
        kernelOneInRealSize<<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_ws, ids_size, newIndexForOne);
        cudaDeviceSynchronize();
        if (verbose) {
            std::cout << "shuffle weights, complete in : " << chrono << std::endl;
            chrono.reset();
        }
        bool cond = true;
        size_t nb_step = 0;
        while (cond) {
            std::cout << ++nb_step << '\r';
            kernelResetPairsAndCond<uint32_t><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, d_cond);
            cudaDeviceSynchronize();
            kernelMazePairForBreakWall<<<RECOMMENDED_CURAND_BLOCK_2D, DEFAULT_THREADS_DIMS_2D>>>(d_pairs, d_ws, d_vWall, d_hWall, d_rngStates, height, width);
            cudaDeviceSynchronize();
            kernelMazeApplyPairs<<<GET_MAX_BLOCKS_2D(height, width), DEFAULT_THREADS_DIMS_2D>>>(d_pairs, d_ws, height, width, d_cond);
            cudaDeviceSynchronize();
            cudaMemcpy(&cond, d_cond, sizeof(bool), cudaMemcpyDefault);
        }
        if (verbose) {
            std::cout << "break walls, complete in : " << nb_step << " step(s), " << chrono << std::endl;
            chrono.reset();
        }
        HANDLE_ERROR(cudaFree(d_rngStates));
        HANDLE_ERROR(cudaFree(d_pairs));
        HANDLE_ERROR(cudaFree(d_ws));
        HANDLE_ERROR(cudaFree(d_cond));
        moveWallToCPU(d_vWall, d_hWall);
        HANDLE_ERROR(cudaFree(d_hWall));
        HANDLE_ERROR(cudaFree(d_vWall));
        if (verbose) std::cout << "transfer maze to CPU and free data GPU, complete in : " << chrono << std::endl;
        if (verbose) std::cout << "maze make (" << height << 'x' << width << ") in : " << chronoAll << std::endl;
    }

    ~MazeCuda() override = default;
};

#include "maze.tpp.cuh"