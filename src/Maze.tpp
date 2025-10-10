#pragma once

#include "MazeBuilder.h"
#include "MazeGridBuilderCPU.h"
#include "MazeSolution.h"
#include "MazeSolver.h"
#include "SolveMazeUBF.h"
#include "utils/UBackendFunc.hpp"

struct BuildMazeUBF : UBackendFunc {
    template <UnsignedIntegral U, Backend_T Backend>
    void call() {
        MazeBuilder<U, Backend>().setVerbosity(verbose).build(maze);
    }

    Maze* maze;
    bool verbose;

    BuildMazeUBF(Maze* maze, const bool verbose) : maze(maze), verbose(verbose) {}
};

template<Backend_T Backend>
Maze Maze::make(const size_t height_, const size_t width_, const size_t seed_, const bool verbose) {
    Maze maze(height_, width_, seed_, verbose);
    auto bm = BuildMazeUBF{&maze, verbose};
    selectAndCallUBackendFunc<BuildMazeUBF, Backend, uint16_t, uint32_t, unsigned long long int>(
        roundToNextPowerOfTwo(maze.getSize()), bm
    );
    return maze;
}

template <Backend_T BackendViewer>
void Maze::solve(const std::string& pngFile, const size_t png_vws, const size_t png_hws, const bool printPath,
                 const bool printMaze, const size_t a_vws, const size_t a_hws, const bool verbose) const {
    auto sm = SolveMazeUBF{*this, pngFile, png_vws, png_hws, printPath, printMaze, a_vws, a_hws, verbose};
    selectAndCallUBackendFunc<SolveMazeUBF, BackendViewer>(
        getGridSize(sm.a_vws, sm.a_hws), sm
    );
}

template <Backend_T Backend>
void Maze::toPNG(const std::string &path) const {
    toPNG<Backend>(path, 3, 3);
}

template <Backend_T Backend>
void Maze::toPNG(const std::string& path, const size_t verticalWallSize, const size_t horizontalWallSize) const {
    auto gsm = GridStringMazeUBF{*this, verticalWallSize, horizontalWallSize, -1, 0, 0, 0};
    selectAndCallUBackendFunc<GridStringMazeUBF, Backend>(
        getGridSize(gsm.vws, gsm.hws), gsm
    );
    toPNG(path, gsm.grid, gsm.vws, gsm.hws);
}

template <UnsignedIntegral U, Backend_T Backend>
void Maze::toPNG(const std::string& path, size_t verticalWallSize, size_t horizontalWallSize,
    std::vector<U> pathValueIndices, std::vector<char> pathValues) const {
    const auto grid = MazeGridBuilder<U, char, Backend>()
    .setPathValues(pathValueIndices, pathValues)
    .setWallAngleValue(0)
    .setWallVerticalValue(0)
    .setWallHorizontalValue(0)
    .setWallVerticalSize(verticalWallSize)
    .setWallHorizontalSize(horizontalWallSize)
    .build(*this);
    toPNG(path, grid, verticalWallSize, horizontalWallSize);
}

template <UnsignedIntegral U, Backend_T Backend>
std::ostream& Maze::print(std::ostream& os, size_t verticalWallSize, size_t horizontalWallSize,
    std::vector<U> pathValueIndices, std::vector<char> pathValues) const {
    const auto grid = MazeGridBuilder<U, char, Backend>()
    .setPathValues(pathValueIndices, pathValues)
    .setWallAngleValue('+')
    .setWallVerticalValue('|')
    .setWallHorizontalValue('-')
    .setWallVerticalSize(verticalWallSize)
    .setWallHorizontalSize(horizontalWallSize)
    .build(*this);
    return print(os, grid, verticalWallSize, horizontalWallSize);
}