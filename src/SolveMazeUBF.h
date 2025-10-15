#pragma once

#include "utils/UBackendFunc.hpp"
#include "utils/chronometer.hpp"
#include "MazeSolution.h"
#include "MazeSolver.h"

struct SolveMaze {
    Maze const * maze;
    std::string pngFile;
    size_t png_vws, png_hws;
    bool printPath, printMaze;
    size_t a_vws, a_hws;
    bool verbose;
};

struct SolveMazeUBF : UBackendFunc, SolveMaze {
    template <UnsignedIntegral U, Backend_T Backend>
    void call() {
        auto chrono = Chronometer();
        MazeSolution<U> solution = {
            {},
            {},
            {0, 0},
            {static_cast<U>(maze->getWidth()-1), static_cast<U>(maze->getHeight()-1)},
            false,
            0
        };
        MazeSolver<U, BackendCPU>().solve(*maze, solution);
        solution.makePath(*maze, verbose || printPath, true);
        if (verbose) std::cout << "Solve Maze in : " << chrono << std::endl;
        chrono.reset();
        if (printMaze) {
            std::vector pathValues(solution.maxDistance, ' ');
            pathValues[0] = ':';
            maze->print<U, Backend>(std::cout, a_vws, a_hws, solution.distanceToEnd, pathValues) << std::endl;
            if (verbose) std::cout << "Print maze solve in : " << chrono << std::endl;
        }
        chrono.reset();
        if (!pngFile.empty()) {
            std::vector<char> pathValues(solution.maxDistance);
            pathValues[0] = static_cast<char>(255);
            for (size_t i = 1; i < solution.maxDistance; ++i) {
                pathValues[i] = static_cast<char>(16 + i*207 / solution.maxDistance);
            }
            maze->toPNG<U, Backend>(pngFile, png_vws, png_hws, solution.distanceToEnd, pathValues);
            if (verbose) std::cout << "Save maze solve to PNG in : " << chrono << std::endl;
        }
    }

    explicit SolveMazeUBF(const SolveMaze& data) : SolveMaze(data) {}
};
