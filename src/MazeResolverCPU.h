#pragma once

#include "MazeResolver.h"

template <UnsignedIntegral GRID_TYPE>
class MazeResolver<GRID_TYPE, BackendCPU> {
public:
    void resolve(const Maze& maze, MazeSolution<GRID_TYPE>& solution);
};

#include "MazeResolverCPU.tpp"