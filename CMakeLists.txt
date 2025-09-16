cmake_minimum_required(VERSION 3.29)
set(CMAKE_CUDA_ARCHITECTURES "native")
project(cuda_maze CUDA CXX)

set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CXX_STANDARD 20)

file(GLOB_RECURSE SOURCES
        "third_party/*.h"
        "third_party/*.hpp"
        "src/*.hpp"
        "src/*.h"
        "src/*.cu"
        "src/*.cpp"
)


add_executable(${PROJECT_NAME} ${SOURCES})

set_target_properties(${PROJECT_NAME} PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
)
