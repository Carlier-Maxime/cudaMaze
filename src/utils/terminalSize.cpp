#include <iostream>
#include <cstdio>
#include <string>

#ifdef __linux__
#include <unistd.h>
#include <sys/ioctl.h>
#endif

#ifdef _WIN32
#include <windows.h>
#endif

std::tuple<size_t, size_t> getTerminalSize(const std::ostream& os) {
    int columns = 0;
    int rows = 0;

    const char* cols_env = std::getenv("COLUMNS");
    const char* rows_env = std::getenv("LINES");
    if (cols_env) {
        try {
            columns = std::stoi(cols_env);
        } catch (...) {}
    }

    if (rows_env) {
        try {
            rows = std::stoi(rows_env);
        } catch (...) {}
    }

    if (columns > 0 && rows > 0) return {columns, rows};

    FILE* file_ptr = nullptr;
    if (&os == &std::cout) {
        file_ptr = stdout;
    } else if (&os == &std::cerr) {
        file_ptr = stderr;
    } else {
        return {0, 0};
    }

    #ifdef __linux__
    if (isatty(fileno(file_ptr))) {
        winsize ws{};
        if (ioctl(fileno(file_ptr), TIOCGWINSZ, &ws) == 0) {
            columns = ws.ws_col;
            rows = ws.ws_row;
        }
    }
    #endif

    #ifdef _WIN32
    HANDLE hConsole;
    if (file_ptr == stdout) {
        hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    } else if (file_ptr == stderr) {
        hConsole = GetStdHandle(STD_ERROR_HANDLE);
    } else {
        return {0, 0};
    }

    DWORD mode;
    if (GetConsoleMode(hConsole, &mode)) {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(hConsole, &csbi)) {
            columns = csbi.srWindow.Right - csbi.srWindow.Left + 1;
            rows    = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
        }
    }
    #endif

    return {columns, rows};
}