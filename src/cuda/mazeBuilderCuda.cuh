#pragma once

#include <curand_kernel.h>
#include "../MazeBuilder.h"

template <UnsignedIntegral GRID_TYPE>
class MazeBuilder<GRID_TYPE, BackendCUDA> : public MazeBuilderBase {
public:
    MazeBuilder() = default;
protected:
    void checkParam() override;
    void allocData() override;
    void initData() override;
    void shuffleWeights() override;
    void breakWallsStep(bool& cond) override;
    void transferResult() override;
    void freeData() override;
private:
    void debugWeights();
    void debugPairs();
    GRID_TYPE *d_pairs = nullptr, *d_ws = nullptr;
    curandState *d_rngStates = nullptr;
    bool *d_vWall = nullptr, *d_hWall = nullptr, *d_cond = nullptr;
    uint32_t ids_size = 0;
    int rand_size = 0;
};

#include "mazeBuilderCuda.tpp.cuh"
