#pragma once

#include <iostream>

#include "MazeBuilder.h"
#include "MazeGridBuilderCPU.h"
#include "mixte/maze_mixte.cuh"

template<Backend_T Backend>
Maze Maze::make(uint16_t height_, uint16_t width_, size_t seed_, const bool verbose) {
    Maze maze;
    maze.height = height_;
    maze.width = width_;
    maze.seed = seed_;
    maze.verticalWall = {static_cast<bool *>(malloc(maze.getVWallSize()))};
    maze.horizontalWall = {static_cast<bool *>(malloc(maze.getHWallSize()))};
    if (verbose) std::cout << "Maze: " << maze.width << 'x' << maze.height << " with seed " << maze.seed << std::endl;
    MazeBuilder<uint32_t, Backend>().setVerbosity(verbose).build(&maze);
    return maze;
}

template <Backend_T Backend>
void Maze::toPNG(const std::string &path) const {
    toPNG<Backend>(path, 3, 3);
}

template <Backend_T Backend>
void Maze::toPNG(const std::string& path, const size_t verticalWallSize, const size_t horizontalWallSize) const {
    const auto grid = MazeGridBuilder<char, Backend>()
        .setPathValue(-1)
        .setWallAngleValue(0)
        .setWallVerticalValue(0)
        .setWallHorizontalValue(0)
        .setWallVerticalSize(verticalWallSize)
        .setWallHorizontalSize(horizontalWallSize)
        .build(*this);
    toPNG(path, grid, verticalWallSize, horizontalWallSize);
}