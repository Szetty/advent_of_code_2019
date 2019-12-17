#!/usr/local/opt/python/bin/python3.7
import numpy as np

PATTERN = [0, 1, 0, -1]

def digits_to_string(digits):
    return "".join([str(i) for i in digits])

def build_pattern(input_length, i):
    repeated_pattern = np.repeat(PATTERN, i)
    reps = int(np.ceil((input_length + 1) / len(repeated_pattern)))
    resized_pattern = np.tile(repeated_pattern, reps)
    return resized_pattern[1:(input_length + 1)]

def solve1(input):
    input = np.array([int(c) for c in input])
    patterns = np.array([build_pattern(len(input), i + 1) for i in range(len(input))])
    for _ in range(100):
        input = np.remainder(np.abs(patterns.dot(input)), 10)
    return digits_to_string(input[:8])
    
def solve2(input):
    offset = int(input[:7])
    input = np.flip(np.tile([int(c) for c in input], 10000)[offset:])
    for _ in range(100):
        input = np.remainder(np.cumsum(input), 10)
    return digits_to_string(np.flip(input[-8:]))

def tests():
    assert(solve1("80871224585914546619083218645595") == "24176176")
    assert(solve1("19617804207202209144916044189917") == "73745418")
    assert(solve1("69317163492948606335995924319873") == "52432133")
    assert(solve2("03036732577212944063491565474664") == "84462026")
    assert(solve2("02935109699940807407585447034323") == "78725270")
    assert(solve2("03081770884921959731165446850517") == "53553731")

tests()
input = open("inputs/16","r").read()
print(solve1(input))
print(solve2(input))