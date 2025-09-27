#include "Maze.h"

#include <stdexcept>
#include <random>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../third_party/stb_image_write.h"

Maze::Maze() : height(0), width(0), seed(0), verticalWall(nullptr), horizontalWall(nullptr) {
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

size_t Maze::getGridHeight(const size_t verticalWallSize) const {
    return getGridSize(getHeight(), verticalWallSize);
}

size_t Maze::getGridWidth(const size_t horizontalWallSize) const {
    return getGridSize(getWidth(), horizontalWallSize);
}

size_t Maze::getVWallSize() const {
    return (width-1)*height;
}

size_t Maze::getHWallSize() const {
    return (height-1)*width;
}

size_t Maze::getGridSize(const size_t size, const size_t wallSize) {
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
    const auto grid = MazeGridBuilder<char, BackendCPU>()
        .setPathValue(' ')
        .setWallAngleValue('+')
        .setWallVerticalValue('|')
        .setWallHorizontalValue('-')
        .setWallVerticalSize(1)
        .setWallHorizontalSize(3)
        .build(maze);
    os << std::endl;
    for (size_t i = 0; i < maze.getGridHeight(1); i++) {
        for (size_t j = 0; j < maze.getGridWidth(3); j++) {
            os << grid[i*maze.getGridWidth(3)+j];
        }
        os << std::endl;
    }
    return os;
}
