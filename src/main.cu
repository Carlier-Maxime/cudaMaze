#include <iostream>
#include <fstream>
#include <ostream>

#include "../third_party/argparse.hpp"

#include "utils/chronometer.hpp"
#include "backend/Backends.cuh"

int main(int argc, char* argv[]) {
    argparse::ArgumentParser program("maze");

    size_t w = 5;
    program.add_argument("width")
        .help("width of the maze")
        .nargs(argparse::nargs_pattern::optional)
        .store_into(w);

    size_t h = 5;
    program.add_argument("height")
        .help("height of the maze")
        .nargs(argparse::nargs_pattern::optional)
        .store_into(h);

    size_t seed = time(nullptr);
    program.add_argument("--seed")
        .help("seed for the random number generator, actual time is used by default")
        .store_into(seed);

    bool verbose;
    program.add_argument("--verbose").flag()
        .help("verbose mode")
        .store_into(verbose);

    bool asciiMaze;
    program.add_argument("--not_ascii").flag()
        .help("disable print maze using ascii art")
        .store_into(asciiMaze);

    std::string png_file;
    program.add_argument("--png_file")
        .help("save maze to png file")
        .store_into(png_file);

    std::string solutionPngFile;
    program.add_argument("--solution_png_file")
        .help("save maze solve to png file")
        .store_into(solutionPngFile);

    try {
        program.parse_args(argc, argv);
        asciiMaze = !asciiMaze;
    }
    catch (const std::exception& err) {
        std::cerr << err.what() << std::endl;
        std::cerr << program;
        std::exit(EXIT_FAILURE);
    }

    const auto maze = Maze::make<BackendCUDA>(h, w, seed, verbose);
    if (asciiMaze) std::cout << maze << std::endl;
    auto chrono = Chronometer();
    if (!png_file.empty()) {
        maze.toPNG<BackendCUDA>(png_file);
        if (verbose) std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    }
    chrono.reset();
    if (!solutionPngFile.empty()) {
        MazeSolution<size_t> solution = {
            {},
            {},
            {0, 0},
            {maze.getWidth()-1, maze.getHeight()-1},
            false,
            0
        };
        chrono.reset();
        MazeResolver<size_t, BackendCPU>().resolve(maze, solution);
        if (verbose) std::cout << "Solve Maze in : " << chrono << std::endl;
        chrono.reset();
        std::vector<char> pathValues(solution.maxDistance);
        for (size_t i = 0; i < solution.maxDistance; ++i) {
            pathValues[i] = static_cast<char>(32 + i*223 / solution.maxDistance);
        }
        maze.toPNG<size_t, BackendCUDA>("maze_solve.png", 3, 3, solution.distanceToEnd, pathValues);
        if (verbose) std::cout << "Save maze solve to PNG in : " << chrono << std::endl;
    }
    return EXIT_SUCCESS;
}
