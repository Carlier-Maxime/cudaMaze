#pragma once

#include <vector>
#include "utils/math_utils.hpp"

class Maze;

template <UnsignedIntegral U, typename GRID_TYPE>
class MazeGridBuilderBase {
public:
    virtual ~MazeGridBuilderBase() = default;

    MazeGridBuilderBase& setPathValue(const GRID_TYPE &pathValue_) {
        pathValueIndices.clear();
        pathValues.clear();
        pathValues.emplace_back(pathValue_);
        return *this;
    }

    MazeGridBuilderBase& setPathValues(const std::vector<U> indices, const std::vector<GRID_TYPE> values) {
        pathValueIndices = indices;
        pathValues = values;
        return *this;
    }

    MazeGridBuilderBase& setWallAngleValue(const GRID_TYPE &wallAngleValue_) {
        this->wallAngleValue = wallAngleValue_;
        return *this;
    }

    MazeGridBuilderBase& setWallVerticalValue(const GRID_TYPE &wallVerticalValue_) {
        this->wallVerticalValue = wallVerticalValue_;
        return *this;
    }

    MazeGridBuilderBase& setWallHorizontalValue(const GRID_TYPE &wallHorizontalValue_) {
        this->wallHorizontalValue = wallHorizontalValue_;
        return *this;
    }

    MazeGridBuilderBase& setWallVerticalSize(size_t wallVerticalSize_) {
        this->wallVerticalSize = wallVerticalSize_;
        return *this;
    }

    MazeGridBuilderBase& setWallHorizontalSize(size_t wallHorizontalSize_) {
        this->wallHorizontalSize = wallHorizontalSize_;
        return *this;
    }

    [[nodiscard]] virtual std::vector<GRID_TYPE> build(const Maze& maze) const = 0;
protected:
    std::vector<U> pathValueIndices;
    std::vector<GRID_TYPE> pathValues;
    GRID_TYPE wallAngleValue = 0, wallVerticalValue = 0, wallHorizontalValue = 0;
    size_t wallVerticalSize = 0, wallHorizontalSize = 0;
};
