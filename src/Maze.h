#pragma once
#include <cstdint>
#include <string>
#include <vector>

class Maze {
public:
    Maze(uint16_t height_, uint16_t width_, size_t seed_, bool verbose);
    Maze(uint16_t height_, uint16_t width_, size_t seed_);
    Maze(uint16_t height_, uint16_t width_, bool verbose);
    Maze(uint16_t height_, uint16_t width_);
    virtual ~Maze() = default;
    void toPNG(const std::string& path) const;
    [[nodiscard]] size_t getIndexForOne() const;
    [[nodiscard]] size_t getPairsSize() const;
    [[nodiscard]] size_t getSize() const;
    [[nodiscard]] uint16_t getHeight() const;
    [[nodiscard]] uint16_t getWidth() const;
    [[nodiscard]] size_t getSeed() const;
    friend std::ostream& operator<<(std::ostream& os, const Maze& maze);
private:
    uint16_t height, width;
    size_t seed;
protected:
    std::vector<char> grid;
};
