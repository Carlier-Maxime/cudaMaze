#pragma once
#include <queue>

#include "Maze.h"

template <UnsignedIntegral GRID_TYPE>
void MazeSolver<GRID_TYPE, BackendCPU>::solve(const Maze& maze, MazeSolution<GRID_TYPE>& solution) {
    const auto w = maze.getWidth();
    const auto h = maze.getHeight();
    std::queue<Position<GRID_TYPE>> q;
    q.push(solution.end);
    auto& grid = solution.distanceToEnd;
    grid.resize(maze.getSize(), 0);
    const auto& start = solution.start;
    size_t step = 1;
    while (!q.empty() && (!solution.stopWhenPathFound || grid[start.y * w + start.x]==0)) {
        const auto stepSize = q.size();
        for (auto _ = 0; _ < stepSize; _++) {
            const auto p = q.front();
            q.pop();
            if (p.y >= h || p.x >= w) return;
            const auto i = p.y * w + p.x;
            grid[i] = step;
            GRID_TYPE vWallIndex = p.y*(w-1)+p.x;
            GRID_TYPE hWallIndex = i;
            GRID_TYPE vwl = (w-1)*h;
            GRID_TYPE hwl = (h-1)*w;
            if (p.x<w-1 && vWallIndex < vwl && !maze.verticalWall[vWallIndex] && grid[i+1] == 0) q.push({p.x+1, p.y});
            if (p.x>0 && vWallIndex > 0 && !maze.verticalWall[vWallIndex-1] && grid[i-1] == 0) q.push({p.x-1, p.y});
            if (p.y<h-1 && hWallIndex < hwl && !maze.horizontalWall[hWallIndex] && grid[i+w] == 0) q.push({p.x, p.y+1});
            if (p.y>0 && hWallIndex > 0 && !maze.horizontalWall[hWallIndex-w] && grid[i-w] == 0) q.push({p.x, p.y-1});
        }
        ++step;
    }
    solution.maxDistance = step;
}
