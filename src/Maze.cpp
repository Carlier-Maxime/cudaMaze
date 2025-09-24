#include "Maze.h"

#include <stdexcept>
#include <random>
#include <iomanip>
#include <iostream>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../third_party/stb_image_write.h"

Maze::Maze(const uint16_t height_, const uint16_t width_, const size_t seed_, const bool verbose) :
        height(height_), width(width_), seed(seed_), verticalWall((width-1)*height), horizontalWall((height-1)*width) {
    if (verbose) std::cout << "Maze: " << width << 'x' << height << " with seed " << seed << std::endl;
}

Maze::Maze(const uint16_t height_, const uint16_t width_, const size_t seed_): Maze(height_, width_, seed_, false){}

Maze::Maze(const uint16_t height_, const uint16_t width_, const bool verbose): Maze(height_, width_, time(nullptr), verbose){}

Maze::Maze(const uint16_t height_, const uint16_t width_): Maze(height_, width_, false){}

void Maze::toPNG(const std::string& path, const size_t verticalWallSize, const size_t horizontalWallSize) const {
    const auto grid = toGrid<char>(-1, 0, 0, 0, verticalWallSize, horizontalWallSize);
    if (!stbi_write_png(
        path.c_str(), static_cast<int>(getGridWidth(horizontalWallSize)), static_cast<int>(getGridHeight(verticalWallSize)),
        1, grid.data(), static_cast<int>(getGridWidth(horizontalWallSize)))
    ) throw std::runtime_error("Failed to write image");
}

size_t Maze::getIndexForOne() const {
    std::mt19937 rng(getSeed());
    return std::uniform_int_distribution<std::mt19937::result_type>(0, getSize()-1)(rng);
}

size_t Maze::getGridHeight(const size_t verticalWallSize) const {
    return getGridSize(getHeight(), verticalWallSize);
}

size_t Maze::getGridWidth(const size_t horizontalWallSize) const {
    return getGridSize(getWidth(), horizontalWallSize);
}

size_t Maze::getGridSize(const size_t size, const size_t wallSize) {
    return size+size*wallSize+2*wallSize-1;
}

size_t Maze::getSize() const {
    return getHeight() * getWidth();
}

uint16_t Maze::getHeight() const {
    return height;
}

uint16_t Maze::getWidth() const {
    return width;
}

size_t Maze::getSeed() const {
    return seed;
}

std::ostream& operator<<(std::ostream& os, const Maze& maze) {
    const auto grid = maze.toGrid(' ', '+', '|', '-', 1, 3);
    os << std::endl;
    for (size_t i = 0; i < maze.getGridHeight(1); i++) {
        for (size_t j = 0; j < maze.getGridWidth(3); j++) {
            os << grid[i*maze.getGridWidth(3)+j];
        }
        os << std::endl;
    }
    return os;
}
