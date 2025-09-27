#pragma once
#include "utils/chronometer.hpp"

class Maze;

class MazeBuilderBase {
public:
    MazeBuilderBase();
    virtual ~MazeBuilderBase();
    MazeBuilderBase& setVerbosity(bool verbose_);
    void build(Maze* maze_);
    [[nodiscard]] size_t getIndexForOne() const;
private:
    Chronometer chronoAll, chronoStep;
    bool verbose;
protected:
    virtual void checkParam();
    virtual void allocData() = 0;
    virtual void initData() = 0;
    virtual void shuffleWeights() = 0;
    size_t breakWalls();
    virtual void breakWallsStep(bool& cond) = 0;
    virtual void transferResult() = 0;
    virtual void freeData() = 0;
    Maze* maze;
};
