#pragma once

#include <cstdint>
#include <vector>

#include "backend/Backend.h"
#include "utils/math_utils.hpp"

class Maze;

template <UnsignedIntegral GRID_TYPE>
struct MazeSolution {
    std::vector<GRID_TYPE> distanceToEnd;
    std::vector<uint8_t> path;
    Position<GRID_TYPE> start;
    Position<GRID_TYPE> end;
    bool stopWhenPathFound = true;
    GRID_TYPE maxDistance;
};

template <UnsignedIntegral GRID_TYPE, Backend_T Backend>
class MazeResolver {
public:
    void resolve(const Maze& maze, MazeSolution<GRID_TYPE>& solution);
};
