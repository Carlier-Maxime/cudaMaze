#pragma once

#include "MazeSolver.h"

template <UnsignedIntegral GRID_TYPE>
class MazeSolver<GRID_TYPE, BackendCPU> {
public:
    void solve(const Maze& maze, MazeSolution<GRID_TYPE>& solution);
};

#include "MazeSolverCPU.tpp"
