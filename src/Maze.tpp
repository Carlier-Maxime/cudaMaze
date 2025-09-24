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
        const bool yLimit = i==0 || i==h-1;
        for (size_t k = 0; k < (i&1 || yLimit ? wallVerticalSize : 1); ++k) {
            size_t gx = 0;
            for (size_t j = 0; j < w; ++j) {
                const bool xLimit = j==0 || j==w-1;
                for (size_t l = 0; l < (j&1 || xLimit ? wallHorizontalSize : 1); ++l) {
                    const auto index = gy * gw + gx;
                    if (!(i&1) && !(j&1)) grid[index] = wallAngleValue;
                    else if (yLimit) grid[index] = wallHorizontalValue;
                    else if (xLimit) grid[index] = wallVerticalValue;
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
    for (size_t i=0; i<wallVerticalSize; ++i) {
        for (size_t j=0; j<wallHorizontalSize; ++j) {
            grid[(wallVerticalSize+i)*gw+j] = pathValue;
            grid[gh*gw-((wallVerticalSize+i)*gw+j+1)] = pathValue;
        }
    }
    return grid;
}