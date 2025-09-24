#pragma once

#include "Maze.h"

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
    const bool hBorder = i<wallVerticalSize || i>=h-wallVerticalSize;
    const bool vBorder = j<wallHorizontalSize || j>=w-wallHorizontalSize;
    if (hBorder) return vBorder ? wallAngleValue : wallHorizontalValue;
    const bool input = i<2*wallVerticalSize && j<wallHorizontalSize;
    const bool output = i>=h-2*wallVerticalSize && j>=w-wallHorizontalSize;
    if (vBorder) return input || output ? pathValue : wallVerticalValue;
    const size_t y = (i-wallVerticalSize)/(wallVerticalSize+1);
    const bool hWall = (i-wallVerticalSize)%(wallVerticalSize+1) == wallVerticalSize;
    const size_t x = (j-wallHorizontalSize)/(wallHorizontalSize+1);
    const bool vWall = (j-wallHorizontalSize)%(wallHorizontalSize+1) == wallHorizontalSize;
    if (hWall && vWall) return wallAngleValue;
    if (hWall) return horizontalWall[y*getWidth()+x] ? wallHorizontalValue : pathValue;
    if (vWall) return verticalWall[y*(getWidth()-1)+x] ? wallVerticalValue : pathValue;
    return pathValue;
}
