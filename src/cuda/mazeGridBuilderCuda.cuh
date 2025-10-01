#pragma once

#include "../MazeGridBuilder.h"

template <UnsignedIntegral U, typename GRID_TYPE>
class MazeGridBuilder<U, GRID_TYPE, BackendCUDA> : public MazeGridBuilderBase<U, GRID_TYPE> {
public:
    [[nodiscard]] std::vector<GRID_TYPE> build(const Maze& maze) const override;
};

#include "MazeGridBuilderCuda.tpp.cuh"