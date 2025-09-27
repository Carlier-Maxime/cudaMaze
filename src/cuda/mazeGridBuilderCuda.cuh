#pragma once

#include "../MazeGridBuilder.h"

template <typename GRID_TYPE>
class MazeGridBuilder<GRID_TYPE, BackendCUDA> : public MazeGridBuilderBase<GRID_TYPE> {
public:
    [[nodiscard]] std::vector<GRID_TYPE> build(const Maze& maze) const override;
};

#include "MazeGridBuilderCuda.tpp.cuh"