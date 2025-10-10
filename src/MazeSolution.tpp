#pragma once

template <UnsignedIntegral GRID_TYPE>
void MazeSolution<GRID_TYPE>::makePath(const Maze& maze, const bool printPath, const bool setDist0IfPath) {
    const auto h = maze.getHeight(), w = maze.getWidth();
    auto p = start;
    path.reserve(distanceToEnd[start.y * w + start.x]);
    while (p.y != end.y || p.x != end.x) {
        auto i = p.y*w+p.x;
        auto dist = distanceToEnd[i];
        GRID_TYPE vwi = p.y*(w-1)+p.x;
        GRID_TYPE hwi = i;
        GRID_TYPE vwl = maze.getVWallSize();
        GRID_TYPE hwl = maze.getHWallSize();
        if (p.x<w-1 && vwi < vwl && !maze.isVWall(vwi) && distanceToEnd[i+1] > 0 && distanceToEnd[i+1] < dist) {
            path.emplace_back(Direction::Right);
            if (printPath) std::cout << 'R';
            p = {static_cast<GRID_TYPE>(p.x+1), static_cast<GRID_TYPE>(p.y)};
        } else if (p.x>0 && vwi > 0 && !maze.isVWall(vwi-1) && distanceToEnd[i-1] > 0 && distanceToEnd[i-1] < dist) {
            path.emplace_back(Direction::Left);
            if (printPath) std::cout << 'L';
            p = {static_cast<GRID_TYPE>(p.x-1), static_cast<GRID_TYPE>(p.y)};
        } else if (p.y<h-1 && hwi < hwl && !maze.isHWall(hwi) && distanceToEnd[i+w] > 0 && distanceToEnd[i+w] < dist) {
            path.emplace_back(Direction::Down);
            if (printPath) std::cout << 'D';
            p = {static_cast<GRID_TYPE>(p.x), static_cast<GRID_TYPE>(p.y+1)};
        } else if (p.y>0 && hwi > 0 && !maze.isHWall(hwi-w) && distanceToEnd[i-w] > 0 && distanceToEnd[i-w] < dist) {
            path.emplace_back(Direction::Up);
            if (printPath) std::cout << 'U';
            p = {static_cast<GRID_TYPE>(p.x), static_cast<GRID_TYPE>(p.y-1)};
        } else throw std::runtime_error("Invalid path");
        if (setDist0IfPath) distanceToEnd[i] = 0;
    }
    if (setDist0IfPath) distanceToEnd[p.y * w + p.x] = 0;
    if (printPath) std::cout << std::endl;
}