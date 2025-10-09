#include <iostream>
#include <fstream>
#include <ostream>

#include "../third_party/argparse.hpp"

#include "utils/chronometer.hpp"
#include "utils/terminalSize.hpp"
#include "backend/Backends.cuh"

int main(int argc, char* argv[]) {
    argparse::ArgumentParser program("maze");

    const auto ttySize = getTerminalSize(std::cout);
    const auto tw = std::get<0>(ttySize), th = std::get<1>(ttySize);

    size_t w = max(tw/4-2, 3ul);
    program.add_argument("width")
        .help("width of the maze")
        .nargs(argparse::nargs_pattern::optional)
        .store_into(w);

    size_t h = max(th/2-2, 3ul);
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

    bool solve;
    program.add_argument("--solve").flag()
        .help("solve maze and print solution in stdout")
        .store_into(solve);

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
    if (!solutionPngFile.empty() || solve) {
        maze.solve<BackendCPU, BackendCUDA>(solutionPngFile, solve, verbose);
    }
    return EXIT_SUCCESS;
}
