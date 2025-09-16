#include <iostream>
#include <fstream>
#include <chrono>
#include <curand_kernel.h>
#include <ostream>
#include <set>
#include <random>

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
    static auto allocDataGPU(size_t grid_size, size_t pairs_size, size_t cond_size) {
        GRID_TYPE *d_grid, *d_pairs, *d_keys;
        curandState *d_rngStates;
        bool *d_cond;
        HANDLE_ERROR(cudaMalloc(&d_grid, sizeof(GRID_TYPE) * grid_size));
        HANDLE_ERROR(cudaMalloc(&d_rngStates, sizeof(curandState) * grid_size));
        HANDLE_ERROR(cudaMalloc(&d_pairs, sizeof(GRID_TYPE) * pairs_size));
        HANDLE_ERROR(cudaMalloc(&d_keys, sizeof(GRID_TYPE) * pairs_size));
        HANDLE_ERROR(cudaMalloc(&d_cond, sizeof(bool) * cond_size));
        return std::make_tuple(d_grid, d_rngStates, d_pairs, d_keys, d_cond);
    }
public:
    MazeCuda(const uint16_t height_, const uint16_t width_) : Maze(height_, width_) {
        auto chronoAll = Chronometer(), chrono = Chronometer();
        const auto height = getHeight(), width = getWidth();
        const auto size = getSize();
        const uint32_t pairs_size_real_used = (height>>1) * (width>>1);
        const uint32_t ids_size = roundToNextPowerOfTwo(pairs_size_real_used);
        std::cout << "seed : " << getSeed() << std::endl;
        auto [d_grid, d_rngStates, d_pairs, d_keys, d_cond] = allocDataGPU<uint32_t>(size, ids_size, 1);
        std::cout << "allocate data GPU, complete in : " << chrono << std::endl;
        chrono.reset();
        kernelInitCurand<<<GET_MAX_BLOCKS_1D(size), DEFAULT_THREADS_DIMS_1D>>>(getSeed(), d_rngStates, size);
        kernelInitArrayRange1D<uint32_t><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, 1, 1);
        cudaDeviceSynchronize();
        kernelRandomArray<<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_keys, d_rngStates, ids_size);
        cudaDeviceSynchronize();
        std::cout << "init intermediate data, complete in : " << chrono << std::endl;
        chrono.reset();
        cudaBitonicSort<uint32_t>(d_pairs, d_keys, ids_size);
        std::mt19937 rng(getSeed());
        const size_t newIndexForOne = std::uniform_int_distribution<std::mt19937::result_type>(0, pairs_size_real_used)(rng);
        cudaDeviceSynchronize();
        kernelOneInRealPairsSize<<<GET_MAX_BLOCKS_1D(size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, newIndexForOne);
        cudaDeviceSynchronize();
        std::cout << "shuffle pairs, complete in : " << chrono << std::endl;
        HANDLE_ERROR(cudaFree(d_keys));
        auto bd = dim3(
            (width / DEFAULT_THREADS_DIMS_2D.x) + (width%DEFAULT_THREADS_DIMS_2D.x ? 1 : 0),
            (height / DEFAULT_THREADS_DIMS_2D.y) + (height%DEFAULT_THREADS_DIMS_2D.y ? 1 : 0),
            1);
        chrono.reset();
        kernelInitMazeGrid<uint32_t><<<bd, DEFAULT_THREADS_DIMS_2D>>>(d_grid, d_pairs, height, width);
        std::cout << "init grid, complete in : " << chrono << std::endl;
        chrono.reset();
        cudaDeviceSynchronize();
        bool cond = true;
        size_t nb_step = 0;
        while (cond) {
            std::cout << ++nb_step << '\r';
            kernelResetPairsAndCond<uint32_t><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, d_cond);
            cudaDeviceSynchronize();
            kernelMazePairForBreakWall<<<bd, DEFAULT_THREADS_DIMS_2D>>>(d_grid, d_rngStates, d_pairs, height, width);
            cudaDeviceSynchronize();
            kernelMazeApplyPairs<<<bd, DEFAULT_THREADS_DIMS_2D>>>(d_grid, d_pairs, height, width, d_cond);
            cudaDeviceSynchronize();
            cudaMemcpy(&cond, d_cond, sizeof(bool), cudaMemcpyDefault);
        }
        std::cout << "break walls, complete in : " << nb_step << " step(s), " << chrono << std::endl;
        chrono.reset();
        HANDLE_ERROR(cudaFree(d_rngStates));
        HANDLE_ERROR(cudaFree(d_pairs));
        HANDLE_ERROR(cudaFree(d_cond));
        char* d_maze;
        HANDLE_ERROR(cudaMalloc(&d_maze, sizeof(char) * size));
        kernelCastMazeToCharArray<<<bd, DEFAULT_THREADS_DIMS_2D>>>(d_grid, d_maze, size, width);
        cudaDeviceSynchronize();
        HANDLE_ERROR(cudaFree(d_grid));
        cudaMemcpy(grid.data(), d_maze, sizeof(char) * size, cudaMemcpyDefault);
        HANDLE_ERROR(cudaFree(d_maze));
        std::cout << "transfer maze to CPU and free data GPU, complete in : " << chrono << std::endl;
        std::cout << "maze make (" << height << 'x' << width << ") in : " << chronoAll << std::endl;
    }
    ~MazeCuda() override = default;
};

int main() {
    uint16_t h, w;
    std::cout << "width : ";
    std::cin >> w;
    std::cout << "height : ";
    std::cin >> h;
    const MazeCuda maze(h, w);
    auto chrono = Chronometer();
    maze.toPNG("maze.png");
    std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    return EXIT_SUCCESS;
}
