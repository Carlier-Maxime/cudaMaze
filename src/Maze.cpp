#include "Maze.h"

#include <stdexcept>
#include <random>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../third_party/stb_image_write.h"

Maze::Maze(const size_t height_, const size_t width_, const size_t seed_, const bool verbose) :
        height(height_), width(width_), seed(seed_),
        verticalWall(static_cast<bool *>(malloc(getVWallSize()))),
        horizontalWall(static_cast<bool *>(malloc(getHWallSize()))) {
    if (verbose) std::cout << "Maze: " << width << 'x' << height << " with seed " << seed << std::endl;
}

Maze::~Maze() {
    free(verticalWall);
    free(horizontalWall);
}

void Maze::toPNG(const std::string& path, const std::vector<char>& grid, const size_t verticalWallSize, const size_t horizontalWallSize) const {
    if (!stbi_write_png(
        path.c_str(), static_cast<int>(getGridWidth(horizontalWallSize)), static_cast<int>(getGridHeight(verticalWallSize)),
        1, grid.data(), static_cast<int>(getGridWidth(horizontalWallSize)))
    ) throw std::runtime_error("Failed to write image");
}

bool Maze::isVWall(const size_t vWallIndex) const {
    return verticalWall[vWallIndex];
}

bool Maze::isHWall(const size_t hWallIndex) const {
    return horizontalWall[hWallIndex];
}

size_t Maze::getGridHeight(const size_t verticalWallSize) const {
    return getGridSizeOf(getHeight(), verticalWallSize);
}

size_t Maze::getGridWidth(const size_t horizontalWallSize) const {
    return getGridSizeOf(getWidth(), horizontalWallSize);
}

size_t Maze::getGridSize(const size_t verticalWallSize, const size_t horizontalWallSize) const {
    return getGridHeight(verticalWallSize) * getGridWidth(horizontalWallSize);
}

size_t Maze::getVWallSize() const {
    return (width-1)*height;
}

size_t Maze::getHWallSize() const {
    return (height-1)*width;
}

size_t Maze::getGridSizeOf(const size_t size, const size_t wallSize) {
    return size+size*wallSize+2*wallSize-1;
}

size_t Maze::getSize() const {
    return getHeight() * getWidth();
}

size_t Maze::getHeight() const {
    return height;
}

size_t Maze::getWidth() const {
    return width;
}

size_t Maze::getSeed() const {
    return seed;
}

std::ostream& operator<<(std::ostream& os, const Maze& maze) {
    auto gsm = GridStringMazeUBF{maze, 1, 3, ' ', '+', '|', '-'};
    selectAndCallUBackendFunc<GridStringMazeUBF, BackendCPU>(
        maze.getGridSize(gsm.vws, gsm.hws), gsm
    );
    os << std::endl;
    for (size_t i = 0; i < maze.getGridHeight(gsm.vws); i++) {
        for (size_t j = 0; j < maze.getGridWidth(gsm.hws); j++) {
            os << gsm.grid[i*maze.getGridWidth(gsm.hws)+j];
        }
        os << std::endl;
    }
    return os;
}
