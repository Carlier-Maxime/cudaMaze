#pragma once

#include "MazeGridBuilderBase.h"
#include "backend/Backend.h"
#include "utils/UBackendFunc.hpp"

class Maze;

template <UnsignedIntegral U, typename GRID_TYPE, Backend_T Backend>
class MazeGridBuilder : MazeGridBuilderBase<U, GRID_TYPE> {
public:
    [[nodiscard]] std::vector<GRID_TYPE> build(const Maze& maze) const override;
};

struct GridStringMazeUBF : UBackendFunc {
    template <UnsignedIntegral U, Backend_T Backend>
    void call() {
        grid = MazeGridBuilder<U, char, Backend>()
            .setPathValue(pv)
            .setWallAngleValue(awv)
            .setWallVerticalValue(vwv)
            .setWallHorizontalValue(hwv)
            .setWallVerticalSize(vws)
            .setWallHorizontalSize(hws)
            .build(maze);
    }

    const Maze& maze;
    size_t vws, hws;
    char pv, awv, vwv, hwv;
    std::vector<char> grid;

    explicit GridStringMazeUBF(const Maze& maze_, const size_t verticalWallSize, const size_t horizontalWallSize,
                               const char pathValue, const char angleWallValue, const char verticalWallValue,
                               const char horizontalWallValue) : maze(maze_), vws(verticalWallSize),
                                        hws(horizontalWallSize), pv(pathValue), awv(angleWallValue),
                                        vwv(verticalWallValue), hwv(horizontalWallValue) {}
};