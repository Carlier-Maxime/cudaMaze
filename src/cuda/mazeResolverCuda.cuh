#pragma once

#include "../MazeResolver.h"

template <UnsignedIntegral GRID_TYPE>
class MazeResolver<GRID_TYPE, BackendCUDA> {
public:
    void resolve(const Maze& maze, MazeSolution<GRID_TYPE>& solution);
private:
    GRID_TYPE *ws = nullptr;
    bool *cond = nullptr, *vWall = nullptr, *hWall = nullptr;
};

#include "mazeResolverCuda.tpp.cuh"