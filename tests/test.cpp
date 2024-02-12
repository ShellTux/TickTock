#include "TickTock.hpp"
#include <cstddef>

size_t factorial(const size_t number) {
  if (number <= 1) {
    return number * factorial(number - 1);
  }

  return number;
}

int main() {
  auto f = []() { factorial(100); };
  TickTock factorial =
      TickTock().add_algorithm(f, {100000, 100000000, 1000000000});
  factorial.measure();
  factorial.printStats();
  factorial.save("metrics.csv");
  return 0;
}
