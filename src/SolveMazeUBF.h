#pragma once

#include <utility>

#include "utils/UBackendFunc.hpp"
#include "utils/chronometer.hpp"
#include "MazeSolution.h"
#include "MazeSolver.h"

struct SolveMazeUBF : UBackendFunc {
    template <UnsignedIntegral U, Backend_T Backend>
    void call() {
        auto chrono = Chronometer();
        MazeSolution<U> solution = {
            {},
            {},
            {0, 0},
            {static_cast<U>(maze.getWidth()-1), static_cast<U>(maze.getHeight()-1)},
            false,
            0
        };
        MazeSolver<U, BackendCPU>().solve(maze, solution);
        solution.makePath(maze, verbose || printPath, true);
        if (verbose) std::cout << "Solve Maze in : " << chrono << std::endl;
        chrono.reset();
        if (printMaze) {
            std::vector pathValues(solution.maxDistance, ' ');
            pathValues[0] = ':';
            maze.print<U, Backend>(std::cout, a_vws, a_hws, solution.distanceToEnd, pathValues) << std::endl;
            if (verbose) std::cout << "Print maze solve in : " << chrono << std::endl;
        }
        chrono.reset();
        if (!pngFile.empty()) {
            std::vector<char> pathValues(solution.maxDistance);
            pathValues[0] = static_cast<char>(255);
            for (size_t i = 1; i < solution.maxDistance; ++i) {
                pathValues[i] = static_cast<char>(16 + i*207 / solution.maxDistance);
            }
            maze.toPNG<U, Backend>(pngFile, png_vws, png_hws, solution.distanceToEnd, pathValues);
            if (verbose) std::cout << "Save maze solve to PNG in : " << chrono << std::endl;
        }
    }

    const Maze& maze;
    const std::string pngFile;
    const size_t png_vws, png_hws;
    const bool printPath, printMaze;
    const size_t a_vws, a_hws;
    const bool verbose;

    SolveMazeUBF(const Maze& maze_, std::string pngFile_, const size_t png_vws_, const size_t png_hws_,
                 const bool printPath_, const bool printMaze_, const size_t a_vws_, const size_t a_hws_, const bool verbose_) :
            maze(maze_), pngFile(std::move(pngFile_)), png_vws(png_vws_), png_hws(png_hws_), printPath(printPath_),
            printMaze(printMaze_), a_vws(a_vws_), a_hws(a_hws_), verbose(verbose_) {}
};
