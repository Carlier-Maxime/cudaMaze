#pragma once
#include <cstdint>
#include <string>
#include <vector>

class Maze {
public:
    Maze(uint16_t height_, uint16_t width_, size_t seed_, bool verbose);
    Maze(uint16_t height_, uint16_t width_, size_t seed_);
    Maze(uint16_t height_, uint16_t width_, bool verbose);
    Maze(uint16_t height_, uint16_t width_);
    virtual ~Maze() = default;
    template <typename GRID_TYPE>
    std::vector<GRID_TYPE> toGrid(
        GRID_TYPE pathValue, GRID_TYPE wallAngleValue, GRID_TYPE wallVerticalValue,
        GRID_TYPE wallHorizontalValue, size_t wallVerticalSize, size_t wallHorizontalSize) const;
    void toPNG(const std::string& path, size_t verticalWallSize, size_t horizontalWallSize) const;
    [[nodiscard]] size_t getIndexForOne() const;
    [[nodiscard]] size_t getGridHeight(size_t verticalWallSize) const;
    [[nodiscard]] size_t getGridWidth(size_t horizontalWallSize) const;
    [[nodiscard]] size_t getSize() const;
    [[nodiscard]] uint16_t getHeight() const;
    [[nodiscard]] uint16_t getWidth() const;
    [[nodiscard]] size_t getSeed() const;
    friend std::ostream& operator<<(std::ostream& os, const Maze& maze);
private:
    static size_t getGridSize(size_t size, size_t wallSize);
    uint16_t height, width;
    size_t seed;
protected:
    std::vector<bool> verticalWall, horizontalWall;
};

#include "Maze.tpp"