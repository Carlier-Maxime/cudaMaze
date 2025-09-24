#pragma once

#include "Maze.h"

template <typename GRID_TYPE>
std::vector<GRID_TYPE> Maze::toGrid(
            const GRID_TYPE pathValue, const GRID_TYPE wallAngleValue, const GRID_TYPE wallVerticalValue,
            const GRID_TYPE wallHorizontalValue, const size_t wallVerticalSize, const size_t wallHorizontalSize) const {
    const auto h = getGridHeight(1);
    const auto w = getGridWidth(1);
    const auto gh = getGridHeight(wallVerticalSize);
    const auto gw = getGridWidth(wallHorizontalSize);
    std::vector<GRID_TYPE> grid(gh*gw);
    size_t gy = 0;
    for (size_t i = 0; i < h; ++i) {
        for (size_t k = 0; k < (i&1 ? wallVerticalSize : 1); ++k) {
            size_t gx = 0;
            for (size_t j = 0; j < w; ++j) {
                for (size_t l = 0; l < (j&1 ? wallHorizontalSize : 1); ++l) {
                    const auto index = gy * gw + gx;
                    if (!(i&1) && !(j&1)) grid[index] = wallAngleValue;
                    else if (i==0 || i==h-1) grid[index] = wallHorizontalValue;
                    else if (j==0 || j==w-1) grid[index] = wallVerticalValue;
                    else if (i&1 && j&1) grid[index] = pathValue;
                    else {
                        const auto y = (i-(i&1))>>1, x = (j-(j&1))>>1;
                        if (!(i&1)) grid[index] = horizontalWall[(y-1)*getWidth()+x] ? wallHorizontalValue : pathValue;
                        else grid[index] = verticalWall[y*(getWidth()-1)+(x-1)] ? wallVerticalValue : pathValue;
                    }
                    ++gx;
                }
            }
            ++gy;
        }
    }
    for (size_t i=1; i<=wallVerticalSize; ++i) {
        grid[i*gw] = pathValue;
        grid[gh*gw-(i*gw+1)] = pathValue;
    }
    return grid;
}