#pragma once

#include "Maze.h"

template <typename GRID_TYPE>
std::vector<GRID_TYPE> Maze::toGrid(
            const GRID_TYPE pathValue, const GRID_TYPE wallAngleValue, const GRID_TYPE wallVerticalValue,
            const GRID_TYPE wallHorizontalValue, const size_t wallVerticalSize, const size_t wallHorizontalSize) const {
    const size_t h = getGridHeight();
    const size_t w = getGridWidth();
    std::vector<GRID_TYPE> grid(h*w);
    for (size_t i = 0; i < h; i++) {
        for (size_t j = 0; j < w; j++) {
            const auto index = i * w + j;
            if (!(i&1) && !(j&1)) grid[index] = wallAngleValue;
            else if (i==0 || i==h-1) grid[index] = wallHorizontalValue;
            else if (j==0 || j==w-1) grid[index] = wallVerticalValue;
            else if (i&1 && j&1) grid[index] = pathValue;
            else {
                const auto y = (i-(i&1))>>1, x = (j-(j&1))>>1;
                if (!(i&1)) grid[index] = horizontalWall[(y-1)*getWidth()+x] ? wallHorizontalValue : pathValue;
                else grid[index] = verticalWall[y*(getWidth()-1)+(x-1)] ? wallVerticalValue : pathValue;
            }
        }
    }
    grid[w] = pathValue;
    grid[h*w-(w+1)] = pathValue;
    return grid;
}