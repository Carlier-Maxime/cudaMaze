#include <iostream>
#include <fstream>
#include <chrono>
#include <vector>
#include <iomanip>
#include <curand_kernel.h>
#include <ostream>
#include <set>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <random>

#include "../third_party/stb_image_write.h"
#include "utils/chronometer.hpp"
#include "utils/math_utils.hpp"
#include "cuda/random.cuh"
#include "cuda/utils.cuh"
#include "cuda/sort.cuh"
#include "cuda/array.cuh"

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
__host__ void checkCudaPairs(GRID_TYPE *d_pairs, size_t size) {
    auto arr = cudaArrayToHost(d_pairs, size);
    const auto unique = std::set<uint32_t>(arr.begin(), arr.end());
    std::cout << arr.size() << ' ' << unique.size() << std::endl;
}

template <typename GRID_TYPE>
__global__ void kernelOneInRealPairsSize(GRID_TYPE *pairs, const size_t size, size_t newIndexForOne) {
    const auto i = d_getArray1DIndex();
    if (i >= size || i!=newIndexForOne || pairs[i] != 1) return;
    pairs[i] = pairs[newIndexForOne];
    pairs[newIndexForOne] = 1;
}

template <typename MAZE_SOURCE_TYPE>
__global__ void kernelCastMazeToCharArray(MAZE_SOURCE_TYPE *source_maze, char *target_maze, const size_t size, const size_t width) {
    const auto [y, x, i] = d_getArray2DIndices(width);
    if (i < size) target_maze[i] = source_maze[i] == 0 ? 0 : 255;
}

class Maze {
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
    uint16_t height, width;
    std::vector<char> grid;
public:
    Maze(const uint16_t height_, const uint16_t width_) : height(height_+(height_&1)), width(width_+(width_&1)), grid(height*width) {
        auto chronoAll = Chronometer(), chrono = Chronometer();
        const auto size = height * width;
        const uint32_t pairs_size_real_used = (height>>1) * (width>>1);
        const uint32_t ids_size = roundToNextPowerOfTwo(pairs_size_real_used);
        const auto seed = time(nullptr);
        std::cout << "seed : " << seed << std::endl;
        auto [d_grid, d_rngStates, d_pairs, d_keys, d_cond] = allocDataGPU<uint32_t>(size, ids_size, 1);
        std::cout << "allocate data GPU, complete in : " << chrono << std::endl;
        chrono.reset();
        kernelInitCurand<<<GET_MAX_BLOCKS_1D(size), DEFAULT_THREADS_DIMS_1D>>>(seed, d_rngStates, size);
        kernelInitArrayRange1D<uint32_t><<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, 1, 1);
        cudaDeviceSynchronize();
        kernelRandomArray<<<GET_MAX_BLOCKS_1D(ids_size), DEFAULT_THREADS_DIMS_1D>>>(d_keys, d_rngStates, ids_size);
        cudaDeviceSynchronize();
        std::cout << "init intermediate data, complete in : " << chrono << std::endl;
        chrono.reset();
        cudaBitonicSort<uint32_t>(d_pairs, d_keys, ids_size);
        std::random_device dev;
        std::mt19937 rng(dev());
        std::uniform_int_distribution<std::mt19937::result_type> dist(0, pairs_size_real_used);
        cudaDeviceSynchronize();
        kernelOneInRealPairsSize<<<GET_MAX_BLOCKS_1D(size), DEFAULT_THREADS_DIMS_1D>>>(d_pairs, ids_size, dist(rng));
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
    ~Maze() = default;
    friend std::ostream& operator<<(std::ostream& os, const Maze& maze) {
        const auto w = [maze] {
            uint32_t w=1;
            for (uint32_t c=10, t=roundToNextPowerOfTwo((maze.height>>1)*(maze.width>>1)); t>c; w++, c*=10){}
            return w;
        }();
        os << std::endl;
        for (uint16_t i = 0; i < maze.height; i++) {
            os << '|';
            for (uint16_t j = 0; j < maze.width; j++) {
                os << std::setw(static_cast<int>(w)) << std::setfill(' ') << static_cast<uint8_t>(maze.grid[i * maze.width + j]) << '|';
            }
            os << std::endl;
        }
        return os;
    }
    void toPNG(const std::string& path) const {
        if (!stbi_write_png(path.c_str(), width, height, 1, grid.data(), width))
            throw std::runtime_error("Failed to write image");
    }
};

int main() {
    uint16_t h, w;
    std::cout << "height : ";
    std::cin >> h;
    std::cout << "width : ";
    std::cin >> w;
    const Maze maze(h, w);
    auto chrono = Chronometer();
    maze.toPNG("maze.png");
    std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    return EXIT_SUCCESS;
}
