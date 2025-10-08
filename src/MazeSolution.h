#pragma once
#include <vector>

#include "utils/math_utils.hpp"
#include "utils/Direction.hpp"

class Maze;

template <UnsignedIntegral GRID_TYPE>
struct MazeSolution {
    std::vector<GRID_TYPE> distanceToEnd;
    std::vector<Direction> path;
    Position<GRID_TYPE> start;
    Position<GRID_TYPE> end;
    bool stopWhenPathFound = true;
    GRID_TYPE maxDistance;

    void makePath(const Maze& maze, bool verbose);
};

#include "MazeSolution.tpp"