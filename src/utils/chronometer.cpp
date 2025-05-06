#include "chronometer.hpp"

Chronometer::Chronometer() : start(std::chrono::high_resolution_clock::now()) {}
void Chronometer::reset() {
    start = std::chrono::high_resolution_clock::now();
}
long Chronometer::elapsed() const {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now() - start).count();
}
std::ostream & operator<<(std::ostream &os, const Chronometer &obj) {
    return os << obj.elapsed() << " ms";
}
