#include <iostream>
#include <fstream>
#include <chrono>
#include <ostream>

#include "utils/chronometer.hpp"
#include "cuda/mazeBuilderCuda.cuh"
#include "cuda/mazeGridBuilderCuda.cuh"
#include "cuda/mazeResolverCuda.cuh"

int main() {
    uint16_t h, w;
    std::cout << "width : ";
    std::cin >> w;
    std::cout << "height : ";
    std::cin >> h;
    auto maze = Maze::make<BackendCUDA>(h, w, time(nullptr), true);
    auto chrono = Chronometer();
    maze.toPNG<BackendCUDA>("maze.png");
    std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    if (maze.getSize() < 1024) std::cout << maze << std::endl;
    else std::cout << "maze not print because size is big (" << maze.getSize() << ')' << std::endl;
    MazeSolution<size_t> solution = {
        {},
        {},
        {0, 0},
        {maze.getWidth()-1, maze.getHeight()-1},
        false,
        0
    };
    chrono.reset();
    MazeResolver<size_t, BackendCUDA>().resolve(maze, solution);
    std::cout << "Solve Maze in : " << chrono << std::endl;
    chrono.reset();
    std::vector<char> pathValues(solution.maxDistance);
    for (size_t i = 0; i < solution.maxDistance; ++i) {
        pathValues[i] = 32 + i*223 / solution.maxDistance;
    }
    maze.toPNG<size_t, BackendCUDA>("maze_solve.png", 3, 3, solution.distanceToEnd, pathValues);
    std::cout << "Save maze solve to PNG in : " << chrono << std::endl;
    return EXIT_SUCCESS;
}
