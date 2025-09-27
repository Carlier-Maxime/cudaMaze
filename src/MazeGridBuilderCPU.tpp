#pragma once

#include "mixte/maze_mixte.cuh"

template <typename GRID_TYPE>
std::vector<GRID_TYPE> MazeGridBuilder<GRID_TYPE, BackendCPU>::build(const Maze& maze) const {
    const auto h = maze.getGridHeight(this->wallVerticalSize);
    const auto w = maze.getGridWidth(this->wallHorizontalSize);
    std::vector<GRID_TYPE> grid(h*w);
    for (size_t i = 0; i < h; ++i) {
        for (size_t j = 0; j < w; ++j) {
            const auto index = i * w + j;
            grid[index] = getGridElementValueOf_Impl(
                h, w, i, j,this->wallVerticalSize, this->wallHorizontalSize,
                this->pathValue, this->wallAngleValue, this->wallVerticalValue,
                this->wallHorizontalValue, maze.verticalWall, maze.horizontalWall, maze.getWidth()
            );
        }
    }
    return grid;
}