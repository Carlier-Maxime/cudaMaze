#pragma once
#include <cstdint>
#include <string>
#include <vector>

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wredefinition-of-typedef"
#endif

class Maze {
public:
    Maze(uint16_t height_, uint16_t width_, size_t seed_, bool verbose);
    Maze(uint16_t height_, uint16_t width_, size_t seed_);
    Maze(uint16_t height_, uint16_t width_, bool verbose);
    Maze(uint16_t height_, uint16_t width_);
    virtual ~Maze() = default;
    template <typename GRID_TYPE>
    std::vector<GRID_TYPE> toGrid(GRID_TYPE wall_value, GRID_TYPE path_value) const;
    void toPNG(const std::string& path) const;
    [[nodiscard]] size_t getIndexForOne() const;
    [[nodiscard]] size_t getGridHeight() const;
    [[nodiscard]] size_t getGridWidth() const;
    [[nodiscard]] size_t getSize() const;
    [[nodiscard]] uint16_t getHeight() const;
    [[nodiscard]] uint16_t getWidth() const;
    [[nodiscard]] size_t getSeed() const;
    friend std::ostream& operator<<(std::ostream& os, const Maze& maze);
private:
    uint16_t height, width;
    size_t seed;
protected:
    std::vector<bool> horizontalWall;
    std::vector<bool> verticalWall;
};

#include "Maze.tpp"

#if defined(__clang__)
#pragma clang diagnostic pop
#endif