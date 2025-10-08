#pragma once

template <UnsignedIntegral GRID_TYPE>
void MazeSolution<GRID_TYPE>::makePath(const Maze& maze, const bool verbose) {
    const auto h = maze.getHeight(), w = maze.getWidth();
    auto p = start;
    path.reserve(distanceToEnd[start.y * w + start.x]);
    while (p.y != end.y || p.x != end.x) {
        auto i = p.y*w+p.x;
        auto dist = distanceToEnd[i];
        GRID_TYPE vWallIndex = p.y*(w-1)+p.x;
        GRID_TYPE hWallIndex = i;
        GRID_TYPE vwl = maze.getVWallSize();
        GRID_TYPE hwl = maze.getHWallSize();
        if (p.x<w-1 && vWallIndex < vwl && !maze.isVWall(vWallIndex) && distanceToEnd[i+1] < dist) {
            path.emplace_back(Direction::Right);
            if (verbose) std::cout << 'R';
            p = {p.x+1, p.y};
        } else if (p.x>0 && vWallIndex > 0 && !maze.isVWall(vWallIndex-1) && distanceToEnd[i-1] < dist) {
            path.emplace_back(Direction::Left);
            if (verbose) std::cout << 'L';
            p = {p.x-1, p.y};
        } else if (p.y<h-1 && hWallIndex < hwl && !maze.isHWall(hWallIndex) && distanceToEnd[i+w] < dist) {
            path.emplace_back(Direction::Down);
            if (verbose) std::cout << 'D';
            p = {p.x, p.y+1};
        } else if (p.y>0 && hWallIndex > 0 && !maze.isHWall(hWallIndex-w) && distanceToEnd[i-w] < dist) {
            path.emplace_back(Direction::Up);
            if (verbose) std::cout << 'U';
            p = {p.x, p.y-1};
        } else throw std::runtime_error("Invalid path");
    }
    std::cout << std::endl;
}