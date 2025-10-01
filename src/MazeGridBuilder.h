#pragma once

#include "MazeGridBuilderBase.h"
#include "utils/Backend.h"

class Maze;

template <UnsignedIntegral U, typename GRID_TYPE, Backend_T Backend>
class MazeGridBuilder : MazeGridBuilderBase<U, GRID_TYPE> {
public:
    [[nodiscard]] std::vector<GRID_TYPE> build(const Maze& maze) const override;
};
