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
void MazeCuda<GRID_TYPE>::moveWallToCPU(const bool* d_vWall, const bool* d_hWall) {
    cudaMemcpy(verticalWall, d_vWall, sizeof(char) * getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(horizontalWall, d_hWall, sizeof(char) * getHWallSize(), cudaMemcpyDefault);
}

template<typename GRID_TYPE>
void MazeCuda<GRID_TYPE>::moveWallToGPU(bool *d_vWall, bool *d_hWall) const {
    cudaMemcpy(d_vWall, verticalWall, sizeof(char) * getVWallSize(), cudaMemcpyDefault);
    cudaMemcpy(d_hWall, horizontalWall, sizeof(char) * getHWallSize(), cudaMemcpyDefault);
}
