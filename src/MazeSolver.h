#pragma once

#include "backend/Backend.h"
#include "utils/math_utils.hpp"
#include "MazeSolution.h"

template <UnsignedIntegral GRID_TYPE, Backend_T Backend>
class MazeSolver {
public:
    void solve(const Maze& maze, MazeSolution<GRID_TYPE>& solution);
};
