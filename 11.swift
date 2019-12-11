#!/usr/bin/swift
import Foundation

class IntcodeComputer {
    var codes: [Int64];
    var i: Int = 0;
    var relative_base: Int = 0;
    var halted: Bool = false;

    init(_ codes_str: String) {
        codes = codes_str.split(separator: ",").map { Int64($0)!}
        codes += Array(repeating: Int64(0), count: 10 * codes.count)
    }

    func run_program(_ inputs: [Int64]) -> [Int64] {
        var inputIterator = inputs.makeIterator()
        var outputs: [Int64] = []
        while (true) {
            let (opcode, parameter_modes) = extract_opcode_and_parameter_modes(Int(codes[i]))
            func operand(_ offset: Int) -> Int64 {
                switch(parameter_modes[offset - 1]) {
                    case 0: return codes[Int(codes[i + offset])]
                    case 1: return codes[i + offset]
                    case 2: return codes[relative_base + Int(codes[i + offset])]
                    default: print(String(format: "Operand parameter mode %d does not exist", parameter_modes[offset - 1])); return 0
                }
            }
            func store(_ offset: Int, _ value: Int64) {
                switch(parameter_modes[offset - 1]) {
                    case 0: codes[Int(codes[i + offset])] = value
                    case 2: codes[relative_base + Int(codes[i + offset])] = value
                    default: print(String(format: "Store parameter mode %d does not exist", parameter_modes[offset - 1]))
                }
            }
            switch (opcode) {
                case 1: store(3, operand(1) + operand(2)); i += 4
                case 2: store(3, operand(1) * operand(2)); i += 4
                case 3: let input = inputIterator.next(); if input == nil { return outputs } else { store(1, input!); i += 2 }
                case 4: outputs += [(operand(1))]; i += 2
                case 5: i = (operand(1) != 0 ? Int(operand(2)) : i + 3)
                case 6: i = (operand(1) == 0 ? Int(operand(2)) : i + 3)
                case 7: store(3, (operand(1) < operand(2) ? 1 : 0)); i += 4
                case 8: store(3, (operand(1) == operand(2) ? 1 : 0)); i += 4
                case 9: relative_base += Int(operand(1)); i += 2
                case 99: halted = true; return outputs
                default: print(String(format: "Unrecognized opcode %d", opcode))
            }
        }
    }

    func extract_opcode_and_parameter_modes(_ instruction: Int) -> (Int, [Int]) { 
        (instruction % 100, [(instruction / 100) % 10, (instruction / 1000) % 10, (instruction / 10000) % 10])
    }
};

func intcode_computer_tests() {
    assert((IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8")).run_program([8])[0] == 1)
    assert((IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8")).run_program([5])[0] == 0)
    assert((IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8")).run_program([5])[0] == 1)
    assert((IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8")).run_program([9])[0] == 0)
    assert((IntcodeComputer("3,3,1108,-1,8,3,4,3,99")).run_program([8])[0] == 1)
    assert((IntcodeComputer("3,3,1108,-1,8,3,4,3,99")).run_program([7])[0] == 0)
    assert((IntcodeComputer("3,3,1107,-1,8,3,4,3,99")).run_program([3])[0] == 1)
    assert((IntcodeComputer("3,3,1107,-1,8,3,4,3,99")).run_program([8])[0] == 0)
    assert((IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")).run_program([0])[0] == 0)
    assert((IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")).run_program([8])[0] == 1)
    assert((IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")).run_program([0])[0] == 0)
    assert((IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")).run_program([8])[0] == 1)
    let result = [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99].map { Int64($0) }
    assert((IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99")).run_program([]) == result)
    assert((IntcodeComputer("1102,34915192,34915192,7,4,7,99,0")).run_program([])[0] == 1219070632396864)
    assert((IntcodeComputer("104,1125899906842624,99")).run_program([])[0] == 1125899906842624)
}

struct Point: Hashable {
  let x: Int
  let y: Int
  init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

func paint(program: String, is_starting_position_white: Bool) -> (visited_positions: Set<Point>, white_positions: Set<Point>) {
    let computer = IntcodeComputer(program)
    var position = Point(0, 0)
    var direction = Point(0, 1)
    var visited_positions: Set<Point> = []
    var white_positions: Set<Point> = []
    if is_starting_position_white { white_positions.insert(position) }
    while !computer.halted {
        visited_positions.insert(position)
        let input = white_positions.contains(position) ? 1 : 0
        let outputs = computer.run_program([Int64(input)])
        if outputs[0] == 1 { white_positions.insert(position) }
        if white_positions.contains(position) && outputs[0] == 0 { white_positions.remove(position) }
        direction = outputs[1] == 1 ? Point(direction.y, -direction.x) : Point(-direction.y, direction.x)
        position = Point(position.x + direction.x, position.y + direction.y)
    }
    return (visited_positions, white_positions)
}

func solve1(program: String) {
    let (visited_positions, _) = paint(program: program, is_starting_position_white: false)
    print(visited_positions.count)
}

func solve2(program: String) {
    let (visited_positions, white_positions) = paint(program: program, is_starting_position_white: true)
    let min_x = visited_positions.map { $0.x }.min()!
    let min_y = visited_positions.map { $0.y }.min()!
    let max_x = visited_positions.map { $0.x }.max()!
    let max_y = visited_positions.map { $0.y }.max()!
    (min_y...max_y).reversed().forEach { y in
        print((min_x...max_x).map {white_positions.contains(Point($0, y)) ? "#" : " "}.joined(separator:"")) 
    }
}

intcode_computer_tests()
let content = try String(contentsOfFile: "inputs/11")
solve1(program: content)
solve2(program: content)