#!/usr/bin/env kotlinc -script

import java.io.File

class IntcodeComputer {
    var i: Int = 0
    var relative_base: Int = 0
    var halted: Boolean = false
    var codes: ArrayList<Long> = arrayListOf()

    constructor(codesStr: String) {
        codes.addAll(codesStr.split(",").map { it.toLong() })
        codes.addAll(List(10 * codes.size) { _ -> 0L })
    }

    fun runProgram(inputs: List<Long>): List<Long> {
        var iterator = inputs.iterator()
        var outputs = mutableListOf<Long>()
        while (!halted) {
            val (opcode, parameter_modes) = extract_opcode_and_parameter_modes(codes[i].toInt());
            val operand = { offset: Int ->
                when(parameter_modes[offset - 1]) {
                    0 -> codes[codes[i + offset].toInt()]
                    1 -> codes[i + offset]
                    2 -> codes[relative_base + codes[i + offset].toInt()]
                    else -> throw IllegalArgumentException("Operand parameter mode ${parameter_modes[offset - 1]} does not exist")
                }
            }
            val store = { offset: Int, value: Long ->
                when(parameter_modes[offset - 1]) {
                    0 -> codes[codes[i + offset].toInt()] = value
                    2 -> codes[relative_base + codes[i + offset].toInt()] = value
                    else -> throw IllegalArgumentException("Store parameter mode ${parameter_modes[offset - 1]} does not exist")
                }
            }
            when(opcode) {
                1 -> { store(3, operand(1) + operand(2)); i += 4 }
                2 -> { store(3, operand(1) * operand(2)); i += 4 }
                3 -> { if (!iterator.hasNext()) return outputs; store(1, iterator.next()); i += 2 }
                4 -> { outputs.add(operand(1)); i += 2 }
                5 -> i = if(operand(1) != 0L) operand(2).toInt() else i + 3
                6 -> i = if(operand(1) == 0L) operand(2).toInt() else i + 3
                7 -> { store(3, if(operand(1) < operand(2)) 1 else 0); i += 4 }
                8 -> { store(3, if(operand(1) == operand(2)) 1 else 0); i += 4 }
                9 -> { relative_base += operand(1).toInt(); i += 2 }
                99 -> halted = true
            }
        }
        return outputs
    }

    private	fun extract_opcode_and_parameter_modes(instruction: Int): Pair<Int, List<Int>> {
        return Pair(
            instruction % 100,
            listOf(
                (instruction / 100) % 10,
                (instruction / 1000) % 10,
                (instruction / 10000) % 10
            )
        )
    }

    companion object {
        fun intcode_computer_tests() {
            assertEquals(IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8").runProgram(listOf(8L))[0], 1L)
            assertEquals(IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8").runProgram(listOf(5L))[0], 0L)
            assertEquals(IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8").runProgram(listOf(5L))[0], 1L)
            assertEquals(IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8").runProgram(listOf(9L))[0], 0L)
            assertEquals(IntcodeComputer("3,3,1108,-1,8,3,4,3,99").runProgram(listOf(8L))[0], 1L)
            assertEquals(IntcodeComputer("3,3,1108,-1,8,3,4,3,99").runProgram(listOf(7L))[0], 0L)
            assertEquals(IntcodeComputer("3,3,1107,-1,8,3,4,3,99").runProgram(listOf(3L))[0], 1L)
            assertEquals(IntcodeComputer("3,3,1107,-1,8,3,4,3,99").runProgram(listOf(8L))[0], 0L)
            assertEquals(IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9").runProgram(listOf(0L))[0], 0L)
            assertEquals(IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9").runProgram(listOf(8L))[0], 1L)
            assertEquals(IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1").runProgram(listOf(0L))[0], 0L)
            assertEquals(IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1").runProgram(listOf(8L))[0], 1L)
            var codes = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99"
            assertEquals(IntcodeComputer(codes).runProgram(listOf(5L))[0], 999L)
            assertEquals(IntcodeComputer(codes).runProgram(listOf(8L))[0], 1000L)
            assertEquals(IntcodeComputer(codes).runProgram(listOf(10L))[0], 1001L)
            var result = listOf(109L,1L,204L,-1L,1001L,100L,1L,100L,1008L,100L,16L,101L,1006L,101L,0L,99L)
            assertEquals(IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99").runProgram(listOf<Long>()), result)
            assertEquals(IntcodeComputer("1102,34915192,34915192,7,4,7,99,0").runProgram(listOf<Long>())[0], 1219070632396864L)
            assertEquals(IntcodeComputer("104,1125899906842624,99").runProgram(listOf<Long>())[0], 1125899906842624L)
        }

        private fun assertEquals(a: Any, b: Any) {
            if (!a.equals(b)) {
                throw IllegalArgumentException("Got $a, expecting: $b")
            }
        }   
    }
}

IntcodeComputer.intcode_computer_tests()
val program = File("inputs/21").readText(Charsets.UTF_8)
// !(A * B * C) * D
val springscript1 = listOf(
    "OR A J", "AND B J", "AND C J", "NOT J J", // !(A * B * C)
    "AND D J"
).joinToString("\n")
val output1 = IntcodeComputer(program).runProgram("$springscript1\nWALK\n".toCharArray().map { it.toLong() })
// println(output1.map { it.toChar() })
println(output1[output1.size - 1])
// !(A * (B + E * I) * (C + F * (G + !H))) * D
val springscript2 = listOf(
    "NOT H T","OR G J","OR T J","AND F J","OR C J", //  ((!H + G) * F + C)
    "OR E T","AND I T","OR B T", // (E * I + B)
    "AND T J","AND A J","NOT J J","AND D J"
).joinToString("\n")
val output2 = IntcodeComputer(program).runProgram("$springscript2\nRUN\n".toCharArray().map { it.toLong() })
// println(output2.map { it.toChar() })
println(output2[output2.size - 1])