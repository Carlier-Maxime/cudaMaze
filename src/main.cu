#include <iostream>
#include <fstream>
#include <chrono>
#include <ostream>

#include "utils/chronometer.hpp"
#include "cuda/mazeBuilderCuda.cuh"
#include "cuda/mazeGridBuilderCuda.cuh"

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
    return EXIT_SUCCESS;
}
