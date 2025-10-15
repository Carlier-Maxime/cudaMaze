#pragma once
#include <string>
#include <vector>

#include "backend/Backend.h"
#include "utils/math_utils.hpp"
#include "MazeBuilder.h"

struct SolveMaze;

class Maze final {
public:
    template <Backend_T Backend>
    static Maze make(size_t height_, size_t width_, size_t seed_, bool verbose);
    ~Maze();
    template <Backend_T BackendViewer>
    void solve(SolveMaze& data) const;
    template <Backend_T Backend>
    void toPNG(const std::string& path) const;
    template <Backend_T Backend>
    void toPNG(const std::string& path, size_t verticalWallSize, size_t horizontalWallSize) const;
    template <UnsignedIntegral U, Backend_T Backend>
    void toPNG(const std::string& path, size_t verticalWallSize, size_t horizontalWallSize,
        std::vector<U> pathValueIndices, std::vector<char> pathValues) const;
    void toPNG(const std::string& path, const std::vector<char>& grid, size_t verticalWallSize, size_t horizontalWallSize) const;
    [[nodiscard]] bool isVWall(size_t vWallIndex) const;
    [[nodiscard]] bool isHWall(size_t hWallIndex) const;
    [[nodiscard]] size_t getGridHeight(size_t verticalWallSize) const;
    [[nodiscard]] size_t getGridWidth(size_t horizontalWallSize) const;
    [[nodiscard]] size_t getGridSize(size_t verticalWallSize, size_t horizontalWallSize) const;
    [[nodiscard]] size_t getVWallSize() const;
    [[nodiscard]] size_t getHWallSize() const;
    [[nodiscard]] size_t getSize() const;
    [[nodiscard]] size_t getHeight() const;
    [[nodiscard]] size_t getWidth() const;
    [[nodiscard]] size_t getSeed() const;
    std::ostream& print(std::ostream& os, size_t verticalWallSize, size_t horizontalWallSize) const;
    template <UnsignedIntegral U, Backend_T Backend>
    std::ostream& print(std::ostream& os, size_t verticalWallSize, size_t horizontalWallSize,
        std::vector<U> pathValueIndices, std::vector<char> pathValues) const;
    std::ostream& print(std::ostream& os, const std::vector<char>& grid, size_t verticalWallSize, size_t horizontalWallSize) const;
    friend std::ostream& operator<<(std::ostream& os, const Maze& maze);
private:
    Maze(size_t height_, size_t width_, size_t seed_, bool verbose);
    static size_t getGridSizeOf(size_t size, size_t wallSize);
    size_t height, width;
    size_t seed;
    template <UnsignedIntegral GRID_TYPE, Backend_T Backend>
    friend class MazeBuilder;
    template <UnsignedIntegral U, typename GRID_TYPE, Backend_T Backend>
    friend class MazeGridBuilder;
    template <UnsignedIntegral GRID_TYPE, Backend_T Backend>
    friend class MazeSolver;
protected:
    bool *verticalWall, *horizontalWall;
};

#include "Maze.tpp"