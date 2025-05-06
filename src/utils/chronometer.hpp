#pragma once
#include <chrono>
#include <iostream>

class Chronometer {
public:
    Chronometer();
    void reset();
    [[nodiscard]] long elapsed() const;
    friend std::ostream & operator<<(std::ostream &os, const Chronometer &obj);
private:
    std::chrono::time_point<std::chrono::high_resolution_clock> start;
};
