#include "MazeBuilderBase.h"

#include <iostream>
#include <random>

#include "Maze.h"

MazeBuilderBase::MazeBuilderBase() : chronoAll(), chronoStep(), verbose(false), maze(nullptr) {}

MazeBuilderBase::~MazeBuilderBase() = default;

size_t MazeBuilderBase::getIndexForOne() const {
    std::mt19937 rng(maze->getSeed());
    return std::uniform_int_distribution<std::mt19937::result_type>(0, maze->getSize()-1)(rng);
}

MazeBuilderBase & MazeBuilderBase::setVerbosity(const bool verbose_) {
    verbose = verbose_;
    return *this;
}

void MazeBuilderBase::checkParam() {
    if (maze->getHeight()==0 || maze->getWidth()==0) throw std::runtime_error("MazeBuilderBase::checkParam() failed: height or width is 0");
}

size_t MazeBuilderBase::breakWalls() {
    bool cond = true;
    size_t nb_step = 0;
    while (cond) {
        std::cout << ++nb_step << '\r';
        breakWallsStep(cond);
    }
    return nb_step;
}

void MazeBuilderBase::build(Maze* maze_) {
        maze = maze_;
        if (verbose) {
            chronoAll.reset();
            chronoStep.reset();
        }
        checkParam();
        if (verbose) {
            std::cout << "check parameter, complete in : " << chronoStep << std::endl;
            chronoStep.reset();
        }
        allocData();
        if (verbose) {
            std::cout << "allocate data, complete in : " << chronoStep << std::endl;
            chronoStep.reset();
        }
        initData();
        if (verbose) {
            std::cout << "init data, complete in : " << chronoStep << std::endl;
            chronoStep.reset();
        }
        shuffleWeights();
        if (verbose) {
            std::cout << "shuffle weights, complete in : " << chronoStep << std::endl;
            chronoStep.reset();
        }
        const size_t nb_step = breakWalls();
        if (verbose) {
            std::cout << "break walls, complete in : " << nb_step << " step(s), " << chronoStep << std::endl;
            chronoStep.reset();
        }
        transferResult();
        if (verbose) {
            std::cout << "transfer result, complete in : " << chronoStep << std::endl;
            chronoStep.reset();
        }
        freeData();
        if (verbose) std::cout << "free data, complete in : " << chronoStep << std::endl;
        if (verbose) std::cout << "maze (" << maze->getWidth() << 'x' << maze->getHeight() << ") build complete in : " << chronoAll << std::endl;
}
