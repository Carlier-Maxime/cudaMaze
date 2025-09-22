#pragma once

#include "Maze.h"

template <typename GRID_TYPE>
std::vector<GRID_TYPE> Maze::toGrid(const GRID_TYPE wall_value, const GRID_TYPE path_value) const {
    const size_t h = getGridHeight();
    const size_t w = getGridWidth();
    std::vector<GRID_TYPE> grid(h*w);
    for (size_t i = 0; i < h; i++) {
        for (size_t j = 0; j < w; j++) {
            const auto index = i * w + j;
            if (i==0 || i==h-1 || j==0 || j==w-1 || (!(i&1) && !(j&1))) grid[index] = wall_value;
            else if (i&1 && j&1) grid[index] = path_value;
            else {
                const auto y = (i-(i&1))>>1, x = (j-(j&1))>>1;
                if (!(i&1)) grid[index] = verticalWall[(y-1)*getWidth()+x] ? wall_value : path_value;
                else grid[index] = horizontalWall[y*(getWidth()-1)+(x-1)] ? wall_value : path_value;
            }
        }
    }
    grid[w] = path_value;
    grid[h*w-(w+1)] = path_value;
    return grid;
}