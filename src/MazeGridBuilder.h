#pragma once

#include "MazeGridBuilderBase.h"
#include "utils/Backend.h"

class Maze;

template <typename GRID_TYPE, Backend_T Backend>
class MazeGridBuilder : MazeGridBuilderBase<GRID_TYPE> {
public:
    [[nodiscard]] std::vector<GRID_TYPE> build(const Maze& maze) const override;
};
