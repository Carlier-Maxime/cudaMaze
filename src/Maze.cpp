#include "Maze.h"

#include <stdexcept>
#include <random>
#include <iomanip>
#include <iostream>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../third_party/stb_image_write.h"
#include "utils/math_utils.hpp"

Maze::Maze(const uint16_t height_, const uint16_t width_, const size_t seed_, const bool verbose) :
        height(height_+(height_&1)), width(width_+(width_&1)), seed(seed_), grid(height*width) {
    if (verbose) std::cout << "Maze: " << height << "x" << width << " with seed " << seed << std::endl;
}

Maze::Maze(const uint16_t height_, const uint16_t width_, const size_t seed_): Maze(height_, width_, seed_, false){}

Maze::Maze(const uint16_t height_, const uint16_t width_, const bool verbose): Maze(height_, width_, time(nullptr), verbose){}

Maze::Maze(const uint16_t height_, const uint16_t width_): Maze(height_, width_, false){}

void Maze::toPNG(const std::string& path) const {
    if (!stbi_write_png(path.c_str(), width, height, 1, grid.data(), width))
        throw std::runtime_error("Failed to write image");
}

size_t Maze::getIndexForOne() const {
    std::mt19937 rng(getSeed());
    return std::uniform_int_distribution<std::mt19937::result_type>(0, getPairsSize())(rng);
}

size_t Maze::getPairsSize() const {
    return (height>>1) * (width>>1);
}

size_t Maze::getSize() const {
    return grid.size();
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
