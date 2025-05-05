cmake_minimum_required(VERSION 3.29)
project(cuda_maze CUDA)

set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CXX_STANDARD 20)

add_executable(cuda_maze main.cu
        stb_image_write.h
        main.cu
)

set_target_properties(cuda_maze PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
)
