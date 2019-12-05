#!/usr/local/bin/julia

get_index = (position_str) -> parse(Int, position_str) + 1

add = (operand, store) -> (store(3, operand(1) + operand(2)); 4)
multiply = (operand, store) -> (store(3, operand(1) * operand(2)); 4)
input = (store, id) -> (store(1, id); 2)
jump_if_true = (operand, i) -> operand(1) != 0 ? operand(2) + 1 : i + 3
jump_if_false = (operand, i) -> operand(1) == 0 ? operand(2) + 1 : i + 3
less_than = (operand, store) -> (store(3, operand(1) < operand(2) ? 1 : 0); 4)
equal = (operand, store) -> (store(3, operand(1) == operand(2) ? 1 : 0); 4)
function output(codes, i, operand)
    operand1 = operand(1)
    if codes[i + 2] == "99" 
        return true, operand1 
    end
    if operand1 != 0
        println("Test failed @ " * string(i))
        return true, -1
    end
    false, i + 2
end

function solve(codes, id)
    codes = split(codes, ",")
    length, = size(codes)
    i = 1
    while i <= length
        instruction = lpad(codes[i], 5, "0")
        opcode = instruction[4:5]
        parameter_modes = instruction[1:3] |> reverse |> ((x) -> split(x, ""))
        operand = (offset) -> (
            parse(
                Int,
                parameter_modes[offset] == "0" ? codes[get_index(codes[i + offset])] : codes[i + offset]
            )
        )
        store = (offset, value) -> codes[get_index(codes[i + offset])] = string(value)
        if opcode == "01" i += add(operand, store)
        elseif opcode == "02" i += multiply(operand, store)
        elseif opcode == "03" i += input(store, id)
        elseif opcode == "04"            
            is_done, value = output(codes, i, operand)
            if is_done return value else i = value end
        elseif opcode == "05" i = jump_if_true(operand, i)
        elseif opcode == "06" i = jump_if_false(operand, i)
        elseif opcode == "07" i += less_than(operand, store)
        elseif opcode == "08" i += equal(operand, store)
        end
    end
end

@assert solve("3,9,8,9,10,9,4,9,99,-1,8", "8") == 1
@assert solve("3,9,8,9,10,9,4,9,99,-1,8", "5") == 0
@assert solve("3,9,7,9,10,9,4,9,99,-1,8", "5") == 1
@assert solve("3,9,7,9,10,9,4,9,99,-1,8", "9") == 0
@assert solve("3,3,1108,-1,8,3,4,3,99", "8") == 1
@assert solve("3,3,1108,-1,8,3,4,3,99", "7") == 0
@assert solve("3,3,1107,-1,8,3,4,3,99", "3") == 1
@assert solve("3,3,1107,-1,8,3,4,3,99", "8") == 0
@assert solve("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9", "0") == 0
@assert solve("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9", "8") == 1
@assert solve("3,3,1105,-1,9,1101,0,0,12,4,12,99,1", "0") == 0
@assert solve("3,3,1105,-1,9,1101,0,0,12,4,12,99,1", "8") == 1

codes = read("inputs/5", String)
solve(codes, "1") |> println
solve(codes, "5") |> println