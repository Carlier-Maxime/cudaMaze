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
        false
    };
    MazeResolver<size_t, BackendCUDA>().resolve(maze, solution);
    debugArray2D(solution.distanceToEnd.data(), maze.getWidth(), maze.getHeight(), maze.getSize());
    return EXIT_SUCCESS;
}
