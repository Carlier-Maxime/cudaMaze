#pragma once

#include <iostream>

#include "MazeBuilder.h"
#include "MazeGridBuilderCPU.h"

template<Backend_T Backend>
Maze Maze::make(const size_t height_, const size_t width_, const size_t seed_, const bool verbose) {
    Maze maze(height_, width_, seed_, verbose);
    maze.selectAndBuild<Backend, uint16_t, uint32_t, unsigned long long int>(verbose);
    return maze;
}


template <Backend_T Backend, UnsignedIntegral... Us>
void Maze::selectAndBuild(const bool verbose) {
    const auto max = roundToNextPowerOfTwo(getSize());
    const bool built = (tryBuild<Us, Backend>(max, verbose) || ...);
    if (!built) throw std::runtime_error("Maze::make() failed: size is too big");
}

template <UnsignedIntegral U, Backend_T Backend>
bool Maze::tryBuild(const size_t max, bool verbose) {
    if (static_cast<size_t>(std::numeric_limits<U>::max()) >= max) {
        MazeBuilder<U, Backend>().setVerbosity(verbose).build(this);
        return true;
    }
    return false;
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

template <UnsignedIntegral U, Backend_T Backend>
void Maze::toPNG(const std::string& path, size_t verticalWallSize, size_t horizontalWallSize,
    std::vector<U> pathValueIndices, std::vector<char> pathValues) const {
    const auto grid = MazeGridBuilder<size_t, char, Backend>()
    .setPathValues(pathValueIndices, pathValues)
    .setWallAngleValue(0)
    .setWallVerticalValue(0)
    .setWallHorizontalValue(0)
    .setWallVerticalSize(verticalWallSize)
    .setWallHorizontalSize(horizontalWallSize)
    .build(*this);
    toPNG(path, grid, verticalWallSize, horizontalWallSize);
}