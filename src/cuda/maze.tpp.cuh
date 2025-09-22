#pragma once

template<typename GRID_TYPE>
void MazeCuda<GRID_TYPE>::debugPairs(GRID_TYPE* pairs) {
    auto arr = cudaArrayToHost(pairs, roundToNextPowerOfTwo(getSize()));
    for (auto i=0; i<getSize(); ++i) {
        if (arr[i] == 0) continue;
        std::cout << i+1 << " => " << arr[i] << std::endl;
    }
}

template<typename GRID_TYPE>
void MazeCuda<GRID_TYPE>::debugWeights(GRID_TYPE* ws) {
    auto arr = cudaArrayToHost(ws, getSize());
    uint32_t w=1;
    for (uint32_t c=10, t=roundToNextPowerOfTwo(getSize()); t>c; w++, c*=10){}
    std::cout << std::endl;
    for (auto i=0; i<getHeight(); ++i) {
        std::cout << '|';
        for (auto j=0; j<getWidth(); ++j) {
            std::cout << std::setw(static_cast<int>(w)) << std::setfill(' ') << arr[i*getWidth()+j] << '|';
        }
        std::cout << std::endl;
    }
    std::cout << std::endl;
}

template<typename GRID_TYPE>
void MazeCuda<GRID_TYPE>::moveWallToCPU(const bool* d_hWall, const bool* d_vWall) {
    const auto h_hWall = new char[horizontalWall.size()];
    const auto h_vWall = new char[verticalWall.size()];
    cudaMemcpy(h_hWall, d_hWall, sizeof(char) * horizontalWall.size(), cudaMemcpyDefault);
    cudaMemcpy(h_vWall, d_vWall, sizeof(char) * verticalWall.size(), cudaMemcpyDefault);
    horizontalWall = std::vector<bool>(h_hWall, h_hWall + horizontalWall.size());
    verticalWall = std::vector<bool>(h_vWall, h_vWall + verticalWall.size());
    delete[] h_hWall;
    delete[] h_vWall;
}