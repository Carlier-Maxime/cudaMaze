#pragma once

#include <vector>

class Maze;

template <typename GRID_TYPE>
class MazeGridBuilderBase {
public:
    virtual ~MazeGridBuilderBase() = default;

    MazeGridBuilderBase& setPathValue(const GRID_TYPE &pathValue_) {
        this->pathValue = pathValue_;
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
    GRID_TYPE pathValue = 0, wallAngleValue = 0, wallVerticalValue = 0, wallHorizontalValue = 0;
    size_t wallVerticalSize = 0, wallHorizontalSize = 0;
};
