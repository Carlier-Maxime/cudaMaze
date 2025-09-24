#include <iostream>
#include <fstream>
#include <chrono>
#include <ostream>

#include "utils/chronometer.hpp"
#include "cuda/maze.cuh"

int main() {
    uint16_t h, w;
    std::cout << "width : ";
    std::cin >> w;
    std::cout << "height : ";
    std::cin >> h;
    const MazeCuda<uint32_t> maze(h, w, true);
    const auto chrono = Chronometer();
    maze.toPNG("maze.png", 3, 3);
    std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    return EXIT_SUCCESS;
}
