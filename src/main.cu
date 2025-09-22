#include <iostream>
#include <fstream>
#include <chrono>
#include <curand_kernel.h>
#include <ostream>
#include <set>

#include "Maze.h"
#include "utils/chronometer.hpp"
#include "utils/math_utils.hpp"
#include "cuda/random.cuh"
#include "cuda/utils.cuh"
#include "cuda/sort.cuh"
#include "cuda/array.cuh"
#include "cuda/maze_kernels.cuh"

template <typename GRID_TYPE>
__host__ void checkCudaPairs(GRID_TYPE *d_pairs, size_t size) {
    auto arr = cudaArrayToHost(d_pairs, size);
    const auto unique = std::set<uint32_t>(arr.begin(), arr.end());
    std::cout << arr.size() << ' ' << unique.size() << std::endl;
}

class MazeCuda : public Maze {
    template <typename GRID_TYPE>
    auto allocDataGPU() {
        GRID_TYPE *d_pairs, *d_ws;
        curandState *d_rngStates;
        bool *d_hWall, *d_vWall, *d_cond;
        const auto ids_size = roundToNextPowerOfTwo(getSize());
        const auto rand_size = RECOMMENDED_CURAND_STATE_COUNT;
        HANDLE_ERROR(cudaMalloc(&d_hWall, sizeof(bool) * horizontalWall.size()));
        HANDLE_ERROR(cudaMalloc(&d_vWall, sizeof(bool) * verticalWall.size()));
        HANDLE_ERROR(cudaMalloc(&d_rngStates, sizeof(curandState) * rand_size));
        HANDLE_ERROR(cudaMalloc(&d_pairs, sizeof(GRID_TYPE) * ids_size));
        HANDLE_ERROR(cudaMalloc(&d_ws, sizeof(GRID_TYPE) * ids_size));
        HANDLE_ERROR(cudaMalloc(&d_cond, sizeof(bool) * 1));
        return std::make_tuple(d_hWall, d_vWall, d_rngStates, d_pairs, d_ws, d_cond);
    }
    template <typename GRID_TYPE>
    void moveWallToCPU(GRID_TYPE* d_hWall, GRID_TYPE* d_vWall) {
        const auto h_hWall = new char[horizontalWall.size()];
        const auto h_vWall = new char[verticalWall.size()];
        cudaMemcpy(h_hWall, d_hWall, sizeof(char) * horizontalWall.size(), cudaMemcpyDefault);
        cudaMemcpy(h_vWall, d_vWall, sizeof(char) * verticalWall.size(), cudaMemcpyDefault);
        horizontalWall = std::vector<bool>(h_hWall, h_hWall + horizontalWall.size());
        verticalWall = std::vector<bool>(h_vWall, h_vWall + verticalWall.size());
        delete[] h_hWall;
        delete[] h_vWall;
    }
    template <typename GRID_TYPE>
    void debugWeights(GRID_TYPE* ws) {
        auto arr = cudaArrayToHost(ws, getSize());
        uint32_t w=1;
        for (uint32_t c=10, t=roundToNextPowerOfTwo(getSize()); t>c; w++, c*=10){}
        std::cout << std::endl;
        for (auto i=0; i<getHeight(); ++i) {
            std::cout << '|';
            for (auto j=0; j<getWidth(); ++j) {
                std::cout << std::setw(static_cast<int>(w)) << std::setfill(' ') << arr[i*getWidth()+j] << '|';
            }
            std::cout << std::endl;
        }
        std::cout << std::endl;
    }
    template <typename GRID_TYPE>
    void debugPairs(GRID_TYPE* pairs) {
        auto arr = cudaArrayToHost(pairs, roundToNextPowerOfTwo(getSize()));
        for (auto i=0; i<getSize(); ++i) {
            if (arr[i] == 0) continue;
            std::cout << i+1 << " => " << arr[i] << std::endl;
        }
    }
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
        auto [d_hWall, d_vWall, d_rngStates, d_pairs, d_ws, d_cond] = allocDataGPU<uint32_t>();
        if (verbose) {
            std::cout << "allocate data GPU, complete in : " << chrono << std::endl;
            chrono.reset();
        }
        kernelInitCurand<<<GET_MAX_BLOCKS_1D(rand_size), DEFAULT_THREADS_DIMS_1D>>>(getSeed(), d_rngStates, rand_size);
        kernelInitArrayRange1D<uint32_t><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_ws, ids_size, 1, 1);
        kernelInitArray1D<bool><<<GET_MAX_BLOCKS_1D(horizontalWall.size()), DEFAULT_THREADS_DIMS_1D>>>(d_hWall, horizontalWall.size(), true);
        kernelInitArray1D<bool><<<GET_MAX_BLOCKS_1D(verticalWall.size()), DEFAULT_THREADS_DIMS_1D>>>(d_vWall, verticalWall.size(), true);
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
            kernelMazePairForBreakWall<<<RECOMMENDED_CURAND_BLOCK_2D, DEFAULT_THREADS_DIMS_2D>>>(d_pairs, d_ws, d_hWall, d_vWall, d_rngStates, height, width);
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
        moveWallToCPU(d_hWall, d_vWall);
        HANDLE_ERROR(cudaFree(d_hWall));
        HANDLE_ERROR(cudaFree(d_vWall));
        if (verbose) std::cout << "transfer maze to CPU and free data GPU, complete in : " << chrono << std::endl;
        if (verbose) std::cout << "maze make (" << height << 'x' << width << ") in : " << chronoAll << std::endl;
    }
    ~MazeCuda() override = default;
};

int main() {
    uint16_t h, w;
    std::cout << "width : ";
    std::cin >> w;
    std::cout << "height : ";
    std::cin >> h;
    const MazeCuda maze(h, w, true);
    const auto chrono = Chronometer();
    maze.toPNG("maze.png");
    std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    return EXIT_SUCCESS;
}
