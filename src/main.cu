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

    size_t w = 0;
    program.add_argument("width")
        .help("width of the maze")
        .nargs(argparse::nargs_pattern::optional)
        .store_into(w);

    size_t h = 0;
    program.add_argument("height")
        .help("height of the maze")
        .nargs(argparse::nargs_pattern::optional)
        .store_into(h);

    size_t seed = time(nullptr);
    program.add_argument("--seed", "-s")
        .help("seed for the random number generator, actual time is used by default")
        .store_into(seed);

    bool verbose;
    program.add_argument("--verbose", "-V").flag()
        .help("verbose mode")
        .store_into(verbose);

    bool asciiMaze;
    program.add_argument("--not_ascii", "--notAscii", "-na").flag()
        .help("disable print maze using ascii art")
        .store_into(asciiMaze);

    uint8_t a_vws = 1;
    program.add_argument("--ascii_vertical_wall_size", "--asciiVerticalWallSize", "-avws")
        .help("vertical wall size in ascii art")
        .store_into(a_vws);

    uint8_t a_hws = 3;
    program.add_argument("--ascii_horizontal_wall_size", "--asciiHorizontalWallSize", "-ahws")
        .help("horizontal wall size in ascii art")
        .store_into(a_hws);

    std::string pngFile;
    program.add_argument("--png_file", "--pngFile", "-pf")
        .help("save maze to png file")
        .store_into(pngFile);

    uint8_t png_vws = 3;
    program.add_argument("--png_vertical_wall_size", "--pngVerticalWallSize", "-pvws")
        .help("vertical wall size in png file")
        .store_into(png_vws);

    uint8_t png_hws = 3;
    program.add_argument("--png_horizontal_wall_size", "--pngHorizontalWallSize", "-phws")
        .help("horizontal wall size in png file")
        .store_into(png_hws);

    std::string solutionPngFile;
    program.add_argument("--solution_png_file", "--solutionPngFile", "-Spf")
        .help("save maze solve to png file")
        .store_into(solutionPngFile);

    bool solve;
    program.add_argument("--solve", "-S").flag()
        .help("solve maze and print solution in stdout")
        .store_into(solve);

    try {
        program.parse_args(argc, argv);
        asciiMaze = !asciiMaze;
        if (w==0) {
            const long nw = static_cast<long>(tw)/(1+a_hws)-2;
            w = std::max<size_t>(nw>0 ? nw : 0, 3);
        }
        if (h==0) {
            const long nh = static_cast<long>(th)/(1+a_vws)-2;
            h = std::max<size_t>(nh>0 ? nh : 0, 3);
        }
    }
    catch (const std::exception& err) {
        std::cerr << err.what() << std::endl;
        std::cerr << program;
        std::exit(EXIT_FAILURE);
    }

    const auto maze = Maze::make<BackendCUDA>(h, w, seed, verbose);
    if (asciiMaze) maze.print(std::cout, a_vws, a_hws) << std::endl;
    auto chrono = Chronometer();
    if (!pngFile.empty()) {
        maze.toPNG<BackendCUDA>(pngFile, png_vws, png_hws);
        if (verbose) std::cout << "Save Maze to PNG in : " << chrono << std::endl;
    }
    chrono.reset();
    if (!solutionPngFile.empty() || solve) {
        auto data = SolveMaze{
            nullptr,
            solutionPngFile,
            png_vws,
            png_hws,
            solve,
            solve,
            a_vws,
            a_hws,
            verbose
        };
        maze.solve<BackendCUDA>(data);
    }
    return EXIT_SUCCESS;
}
