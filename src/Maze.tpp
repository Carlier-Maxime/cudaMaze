#pragma once

#include <iostream>

#include "MazeBuilder.h"
#include "MazeGridBuilderCPU.h"

template<Backend_T Backend>
Maze Maze::make(const size_t height_, const size_t width_, const size_t seed_, const bool verbose) {
    Maze maze;
    maze.height = height_;
    maze.width = width_;
    maze.seed = seed_;
    maze.verticalWall = {static_cast<bool *>(malloc(maze.getVWallSize()))};
    maze.horizontalWall = {static_cast<bool *>(malloc(maze.getHWallSize()))};
    if (verbose) std::cout << "Maze: " << maze.width << 'x' << maze.height << " with seed " << maze.seed << std::endl;
    const auto max = roundToNextPowerOfTwo(maze.getSize());
    if (static_cast<size_t>(std::numeric_limits<uint16_t>::max()) > max)
        MazeBuilder<uint16_t, Backend>().setVerbosity(verbose).build(&maze);
    else if (static_cast<size_t>(std::numeric_limits<uint32_t>::max()) > max)
        MazeBuilder<uint32_t, Backend>().setVerbosity(verbose).build(&maze);
    else if (std::numeric_limits<uint64_t>::max() > max)
        MazeBuilder<uint32_t, Backend>().setVerbosity(verbose).build(&maze);
    else throw std::runtime_error("Maze::make() failed: size is too big");
    return maze;
}

template <Backend_T Backend>
void Maze::toPNG(const std::string &path) const {
    toPNG<Backend>(path, 3, 3);
}

template <Backend_T Backend>
void Maze::toPNG(const std::string& path, const size_t verticalWallSize, const size_t horizontalWallSize) const {
    const auto grid = MazeGridBuilder<size_t, char, Backend>()
        .setPathValue(-1)
        .setWallAngleValue(0)
        .setWallVerticalValue(0)
        .setWallHorizontalValue(0)
        .setWallVerticalSize(verticalWallSize)
        .setWallHorizontalSize(horizontalWallSize)
        .build(*this);
    toPNG(path, grid, verticalWallSize, horizontalWallSize);
}