#pragma once

#include "../MazeSolver.h"

template <UnsignedIntegral GRID_TYPE>
class MazeSolver<GRID_TYPE, BackendCUDA> {
public:
    void solve(const Maze& maze, MazeSolution<GRID_TYPE>& solution);
private:
    GRID_TYPE *ws = nullptr;
    Position<GRID_TYPE> *indices = nullptr;
    bool *cond = nullptr, *vWall = nullptr, *hWall = nullptr;
};

#include "mazeSolverCuda.tpp.cuh"
