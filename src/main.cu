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
    const auto chrono = Chronometer();
    maze.toPNG<BackendCUDA>("maze.png");
    std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    std::cout << maze << std::endl;
    MazeSolution<size_t> solution = {
        {},
        {},
        {0, 0},
        {maze.getWidth()-1, maze.getHeight()-1},
        false,
        0
    };
    MazeResolver<size_t, BackendCUDA>().resolve(maze, solution);
    std::vector<char> pathValues(solution.maxDistance);
    for (size_t i = 0; i < solution.maxDistance; ++i) {
        pathValues[i] = 32 + i*223 / solution.maxDistance;
    }
    maze.toPNG<size_t, BackendCUDA>("maze_solve.png", 3, 3, solution.distanceToEnd, pathValues);
    return EXIT_SUCCESS;
}
