#pragma once

#include "Maze.h"
#include "mixte/maze_mixte.cuh"

template <typename GRID_TYPE>
std::vector<GRID_TYPE> Maze::toGrid(
            const GRID_TYPE pathValue, const GRID_TYPE wallAngleValue, const GRID_TYPE wallVerticalValue,
            const GRID_TYPE wallHorizontalValue, const size_t wallVerticalSize, const size_t wallHorizontalSize) const {
    const auto h = getGridHeight(wallVerticalSize);
    const auto w = getGridWidth(wallHorizontalSize);
    std::vector<GRID_TYPE> grid(h*w);
    for (size_t i = 0; i < h; ++i) {
        for (size_t j = 0; j < w; ++j) {
            const auto index = i * w + j;
            grid[index] = getGridElementValue(
                h, w, i, j,wallVerticalSize, wallHorizontalSize,
                pathValue, wallAngleValue, wallVerticalValue, wallHorizontalValue
            );
        }
    }
    return grid;
}

template<typename T>
T Maze::getGridElementValue(const size_t h, const size_t w, const size_t i, const size_t j,
                            const size_t wallVerticalSize, const size_t wallHorizontalSize,
                            const T pathValue, const T wallAngleValue, const T wallVerticalValue,
                            const T wallHorizontalValue) const {
    return getGridElementValueOf(
        h, w, i, j, wallVerticalSize, wallHorizontalSize, pathValue, wallAngleValue,
        wallVerticalValue, wallHorizontalValue, verticalWall, horizontalWall, getWidth()
    );
}

template<typename T>
T Maze::getGridElementValueOf(const size_t h, const size_t w, const size_t i, const size_t j,
                            const size_t wallVerticalSize, const size_t wallHorizontalSize, T pathValue,
                            T wallAngleValue, T wallVerticalValue, T wallHorizontalValue,
                            const bool *vWall, const bool *hWall, const size_t mazeWidth) {
    return getGridElementValueOf_Impl(
        h, w, i, j, wallVerticalSize, wallHorizontalSize, pathValue,
        wallAngleValue, wallVerticalValue, wallHorizontalValue,
        vWall, hWall, mazeWidth
    );
}
