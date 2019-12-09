// compiled with clang++ -std=c++14
#include <string>
#include <iostream>
#include <fstream>
#include <assert.h>
#include <numeric>
#include <boost/algorithm/string.hpp>
#include <boost/format.hpp>

using namespace std;
using namespace boost;

class IntcodeComputer {
    public:
        vector<long> codes;
        int i, relative_base;
        bool halted;

        IntcodeComputer(string codes_str) {
            vector<string> string_codes;
            split(string_codes, codes_str, is_any_of(","), token_compress_on);
            transform(string_codes.begin(), string_codes.end(), back_inserter(codes), [](auto str) { return stol(str); });
            codes.resize(100 * codes.size(), 0);
            i = relative_base =0;
            halted = false;
        }

        vector<long> run_program(vector<long> inputs) {
            vector<long>::const_iterator iterator = inputs.begin();
            vector<long> outputs;
            while (true) {
                int parameter_modes[3];
                auto opcode = extract_opcode_and_parameter_modes(codes[i], parameter_modes);
                auto operand = [parameter_modes, this] (int offset) -> long {
                    switch(parameter_modes[offset - 1]) {
                        case 0: return codes[codes[i + offset]];
                        case 1: return codes[i + offset];
                        case 2: return codes[relative_base + codes[i + offset]];
                        default: throw str(format("Operand parameter mode %d does not exist") % (parameter_modes[offset - 1]));
                    }
                };
                auto store = [parameter_modes, this] (int offset, long value) -> void { 
                    switch(parameter_modes[offset - 1]) {
                        case 0: codes[codes[i + offset]] = value; break;
                        case 2: codes[relative_base + codes[i + offset]] = value; break;
                        default: throw str(format("Store parameter mode %d does not exist") % (parameter_modes[offset - 1]));
                    }
                };
                switch (opcode) {
                    case 1:
                        store(3, operand(1) + operand(2));
                        i += 4;
                        break;
                    case 2:
                        store(3, operand(1) * operand(2));
                        i += 4;
                        break;
                    case 3:
                        if (iterator >= inputs.end()) return outputs;
                        store(1, *iterator);
                        i += 2;
                        iterator++;
                        break;
                    case 4:
                        outputs.push_back(operand(1));
                        i += 2;
                        break;
                    case 5:
                        i = (operand(1) != 0 ? operand(2) : i + 3);
                        break;
                    case 6:
                        i = (operand(1) == 0 ? operand(2) : i + 3);
                        break;
                    case 7:
                        store(3, (operand(1) < operand(2) ? 1 : 0));
                        i += 4;
                        break;
                    case 8:
                        store(3, (operand(1) == operand(2) ? 1 : 0));
                        i += 4;
                        break;
                    case 9:
                        relative_base += operand(1);
                        i += 2;
                        break;
                    case 99:
                        halted = true;
                        return outputs;
                }
            }
        }
    private:
        int extract_opcode_and_parameter_modes(int instruction, int parameter_modes[3]) {
            parameter_modes[0] = (instruction / 100) % 10;
            parameter_modes[1] = (instruction / 1000) % 10;
            parameter_modes[2] = (instruction / 10000) % 10;
            return instruction % 100;
        }
};

void intcode_computer_tests() {
    assert((new IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8"))->run_program({8})[0] == 1);
    assert((new IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8"))->run_program({5})[0] == 0);
    assert((new IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8"))->run_program({5})[0] == 1);
    assert((new IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8"))->run_program({9})[0] == 0);
    assert((new IntcodeComputer("3,3,1108,-1,8,3,4,3,99"))->run_program({8})[0] == 1);
    assert((new IntcodeComputer("3,3,1108,-1,8,3,4,3,99"))->run_program({7})[0] == 0);
    assert((new IntcodeComputer("3,3,1107,-1,8,3,4,3,99"))->run_program({3})[0] == 1);
    assert((new IntcodeComputer("3,3,1107,-1,8,3,4,3,99"))->run_program({8})[0] == 0);
    assert((new IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9"))->run_program({0})[0] == 0);
    assert((new IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9"))->run_program({8})[0] == 1);
    assert((new IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1"))->run_program({0})[0] == 0);
    assert((new IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1"))->run_program({8})[0] == 1);
    vector<long> result = {109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99};
    assert((new IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99"))->run_program({}) == result);
    assert((new IntcodeComputer("1102,34915192,34915192,7,4,7,99,0"))->run_program({})[0] == 1219070632396864);
    assert((new IntcodeComputer("104,1125899906842624,99"))->run_program({})[0] == 1125899906842624);
}

long solve1(string codes) {
    auto computer = new IntcodeComputer(codes);
    auto result = computer->run_program({1});
    if (result.size() > 1) {
        cout << "Following opcodes are not correct: " << endl;
        for (long v: result) {
            cout << v << endl;
        }
        return -1;
    }
    return result[0];
}

long solve2(string codes) { 
    return (new IntcodeComputer(codes))->run_program({2})[0]; 
}

string read_from_file() {
    ifstream ifs("inputs/9");
    string content((istreambuf_iterator<char>(ifs)), (istreambuf_iterator<char>()));
    return content;
}

void run() {
    intcode_computer_tests();
    auto codes = read_from_file();
    cout << solve1(codes) << endl;
    cout << solve2(codes) << endl;
}

int main() {
    try {
        run();
    } catch (string msg) {
        cout << msg << endl;
    }
    return 0;
}