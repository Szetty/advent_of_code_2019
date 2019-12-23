#!/Users/arnold/.rvm/rubies/ruby-2.6.0/bin/ruby
class IntcodeComputer
    def initialize(codesStr)
        @i = 0
        @relative_base = 0
        @halted = false
        @codes = codesStr.split(',').map(&:to_i)
        @codes = @codes + Array.new(10 * @codes.size).fill(0)
    end

    def runProgram(inputs)
        enumerator = inputs.each
        outputs = []
        while !@halted
            opcode, parameterModes = extractOpcodeAndParameterModes(@codes[@i])
            operand = Proc.new do |offset|
                case parameterModes[offset - 1]
                when 0; @codes[@codes[@i + offset]]
                when 1; @codes[@i + offset]
                when 2; @codes[@relative_base + @codes[@i + offset]]
                else; raise "Operand parameter mode #{parameterModes[offset - 1]} does not exist"
                end
            end
            store = Proc.new do |offset, value|
                case parameterModes[offset - 1]
                when 0; @codes[@codes[@i + offset]] = value
                when 2; @codes[@relative_base + @codes[@i + offset]] = value
                else; raise "Store parameter mode #{parameterModes[offset - 1]} does not exist"
                end
            end
            case opcode
            when 1; store.(3, operand.(1) + operand.(2)); @i += 4
            when 2; store.(3, operand.(1) * operand.(2)); @i += 4
            when 3
                begin
                    store.(1, enumerator.next)
                    @i += 2
                rescue StopIteration
                    return outputs
                end
            when 4; outputs << operand.(1); @i += 2
            when 5; @i = operand.(1) != 0 ? operand.(2) : @i + 3
            when 6; @i = operand.(1) == 0 ? operand.(2) : @i + 3
            when 7; store.(3, operand.(1) < operand.(2) ? 1 : 0); @i += 4
            when 8; store.(3, operand.(1) == operand.(2) ? 1 : 0); @i += 4
            when 9; @relative_base += operand.(1); @i += 2
            when 99; @halted = true
            end
        end
        return outputs
    end

    def extractOpcodeAndParameterModes(instruction)
        return instruction % 100, [
            (instruction / 100) % 10,
            (instruction / 1000) % 10,
            (instruction / 10000) % 10
        ] 
    end

    def self.tests()
        raise "Assertion failed" unless IntcodeComputer.new("3,9,8,9,10,9,4,9,99,-1,8").runProgram([8])[0] == 1
        raise "Assertion failed" unless IntcodeComputer.new("3,9,8,9,10,9,4,9,99,-1,8").runProgram([5])[0] == 0
        raise "Assertion failed" unless IntcodeComputer.new("3,9,7,9,10,9,4,9,99,-1,8").runProgram([5])[0] == 1
        raise "Assertion failed" unless IntcodeComputer.new("3,9,7,9,10,9,4,9,99,-1,8").runProgram([9])[0] == 0
        raise "Assertion failed" unless IntcodeComputer.new("3,3,1108,-1,8,3,4,3,99").runProgram([8])[0] == 1
        raise "Assertion failed" unless IntcodeComputer.new("3,3,1108,-1,8,3,4,3,99").runProgram([7])[0] == 0
        raise "Assertion failed" unless IntcodeComputer.new("3,3,1107,-1,8,3,4,3,99").runProgram([3])[0] == 1
        raise "Assertion failed" unless IntcodeComputer.new("3,3,1107,-1,8,3,4,3,99").runProgram([8])[0] == 0
        raise "Assertion failed" unless IntcodeComputer.new("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9").runProgram([0])[0] == 0
        raise "Assertion failed" unless IntcodeComputer.new("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9").runProgram([8])[0] == 1
        raise "Assertion failed" unless IntcodeComputer.new("3,3,1105,-1,9,1101,0,0,12,4,12,99,1").runProgram([0])[0] == 0
        raise "Assertion failed" unless IntcodeComputer.new("3,3,1105,-1,9,1101,0,0,12,4,12,99,1").runProgram([8])[0] == 1
        codes = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99"
        raise "Assertion failed" unless IntcodeComputer.new(codes).runProgram([5])[0] == 999
        raise "Assertion failed" unless IntcodeComputer.new(codes).runProgram([8])[0] == 1000
        raise "Assertion failed" unless IntcodeComputer.new(codes).runProgram([10])[0] == 1001
        result = [109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99]
        raise "Assertion failed" unless IntcodeComputer.new("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99").runProgram([]) == result
        raise "Assertion failed" unless IntcodeComputer.new("1102,34915192,34915192,7,4,7,99,0").runProgram([])[0] == 1219070632396864
        raise "Assertion failed" unless IntcodeComputer.new("104,1125899906842624,99").runProgram([])[0] == 1125899906842624
    end
end

def emptyQueue(queue); l = []; l << queue.pop while !queue.empty?; l; end

def solve1(program)
    def processOutput(queues, output)
        output.each_slice(3).each do |addr, x, y|
            return y if addr == 255
            queues[addr] << x << y
        end
    end
    computers = Array.new(50).fill { IntcodeComputer.new(program) }
    0.upto(49).each { |i| computers[i].runProgram([i]) }
    queues = Array.new(50).fill { Queue.new }
    loop do
        0.upto(49).each { |i|
            input = queues[i].empty? ? [-1] : emptyQueue(queues[i])
            lastY = processOutput(queues, computers[i].runProgram(input))
            return lastY if lastY != nil
        }
    end
end

def solve2(program)
    def processOutput(queues, output, nat)
        output.each_slice(3).each do |addr, x, y|
            if addr == 255
                nat[0] = x
                nat[1] = y
            else
                queues[addr] << x << y
            end
        end
    end
    computers = Array.new(50).fill { IntcodeComputer.new(program) }
    0.upto(49).each { |i| computers[i].runProgram([i]) }
    queues = Array.new(50).fill { Queue.new }
    nat = [-1, -1]
    lastY = nil
    loop do
        0.upto(49).each { |i|
            input = queues[i].empty? ? [-1] : emptyQueue(queues[i])
            processOutput(queues, computers[i].runProgram(input), nat)
        }
        if queues.all?(&:empty?)
            return lastY if lastY == nat[1] && lastY != -1
            queues[0] << nat[0] << nat[1]
            lastY = nat[1]
        end
    end
end

IntcodeComputer.tests()
program = File.read("inputs/23")
p solve1(program)
p solve2(program)