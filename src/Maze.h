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
    template <typename GRID_TYPE>
    std::vector<GRID_TYPE> toGrid(const GRID_TYPE wall_value, const GRID_TYPE path_value) const {
        const size_t h = getGridHeight();
        const size_t w = getGridWidth();
        std::vector<GRID_TYPE> grid(h*w);
        for (size_t i = 0; i < h; i++) {
            for (size_t j = 0; j < w; j++) {
                const auto index = i * w + j;
                if (i==0 || i==h-1 || j==0 || j==w-1 || (!(i&1) && !(j&1))) grid[index] = wall_value;
                else if (i&1 && j&1) grid[index] = path_value;
                else {
                    const auto y = (i-(i&1))>>1, x = (j-(j&1))>>1;
                    if (!(i&1)) grid[index] = verticalWall[(y-1)*getWidth()+x] ? wall_value : path_value;
                    else grid[index] = horizontalWall[y*(getWidth()-1)+(x-1)] ? wall_value : path_value;
                }
            }
        }
        grid[w] = path_value;
        grid[h*w-(w+1)] = path_value;
        return grid;
    }
    void toPNG(const std::string& path) const;
    [[nodiscard]] size_t getIndexForOne() const;
    [[nodiscard]] size_t getGridHeight() const;
    [[nodiscard]] size_t getGridWidth() const;
    [[nodiscard]] size_t getSize() const;
    [[nodiscard]] uint16_t getHeight() const;
    [[nodiscard]] uint16_t getWidth() const;
    [[nodiscard]] size_t getSeed() const;
    friend std::ostream& operator<<(std::ostream& os, const Maze& maze);
private:
    uint16_t height, width;
    size_t seed;
protected:
    std::vector<bool> horizontalWall;
    std::vector<bool> verticalWall;
};
