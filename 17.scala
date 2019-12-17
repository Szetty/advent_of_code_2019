#!/usr/bin/env scala
import scala.collection.mutable.ListBuffer
import scala.io.Source
import scala.collection.immutable.Iterable
import scala.collection.immutable.HashSet
import scala.collection.immutable.HashMap
import scala.collection.immutable.Map

IntcodeComputer.intcode_computer_tests()
val program = Source.fromFile("inputs/17").mkString
val computer = IntcodeComputer(program)
val grid = computer.runProgram(List[Long]()).dropRight(1).map { _.toChar }
assert(Solve.P1(Source.fromFile("tests/17/1").mkString) == 76)
println(Solve.P1(grid))
println(Solve.P2(grid, program))

object Solve {
    final val SCAFFOLD = '#'
    def P1(gridIterable: Iterable[Char]) = {
        var grid = buildGrid(gridIterable)
        var sum = 0
        for((line, i) <- grid.view.zipWithIndex) {
            for((c, j) <- line.view.zipWithIndex) {
                if (!onBound(i, j, grid.size, line.size) && areNeighboursScaffold(grid, i, j) && isScaffold(c)) {
                    sum += (i * j)
                }
            }
        }
        sum
    }
    def P2(gridIterable: Iterable[Char], program: String): Long = {
        val grid = buildGrid(gridIterable)
        val (robotPos, scaffolds) = findRobotPositionAndScaffolds(grid)
        val path = findRobotPath(robotPos, scaffolds)
        val (mainRoutine, functions) = findRobotProgram(path)
        return sendRobotProgram(mainRoutine, functions, program)
    }
    def buildGrid(gridIterable: Iterable[Char]): ListBuffer[ListBuffer[Char]] = {
        var grid = ListBuffer[ListBuffer[Char]]()
        var line = ListBuffer[Char]()
        gridIterable.foreach { c => if (c != 10.toChar) line += c else { grid += line; line = ListBuffer()} }
        grid
    }
    def onBound(i: Int, j: Int, i_size: Int, j_size: Int) = i <= 0 || i >= (i_size - 1) || j <= 0 || j >= (j_size - 1)
    def areNeighboursScaffold(grid: ListBuffer[ListBuffer[Char]], i: Int, j: Int) = {
        isScaffold(grid(i - 1)(j)) && isScaffold(grid(i + 1)(j)) && isScaffold(grid(i)(j - 1)) && isScaffold(grid(i)(j + 1))
    }
    def isScaffold(v: Char) = v == SCAFFOLD
    def neighbours(p: (Int, Int)) = List((p._1 + 1, p._2), (p._1 - 1, p._2), (p._1, p._2 + 1), (p._1, p._2 - 1))
    def applyDirection(p: (Int, Int), d: (Int, Int)) = (p._1 + d._1, p._2 + d._2)
    def computeNewDirection(s: (Int, Int), d: (Int, Int)) = (d._1 - s._1, d._2 - s._2)
    def computeTurning(d0: (Int, Int), d1: (Int, Int)): String = {
        if (d1._1 == -d0._2 && d1._2 == d0._1) return "LL"
        if (d1._1 == d0._2 && d1._2 == -d0._1) return "RR"
        return ""
    }
    def findRobotPositionAndScaffolds(grid: ListBuffer[ListBuffer[Char]]): ((Int, Int), HashSet[(Int, Int)]) = {
        var robotPos: (Int, Int) = (-1, -1)
        var scaffolds = HashSet[(Int, Int)]()
        for((line, i) <- grid.view.zipWithIndex) {
            for((c, j) <- line.view.zipWithIndex) {
                c match {
                    case '^' => robotPos = (i, j)
                    case '#' => scaffolds += ((i, j))
                    case _ => None
                }
            }
        }
        return (robotPos, scaffolds)
    }
    def findRobotPath(robotPos: (Int, Int), scaffolds: HashSet[(Int, Int)]): String = {
        var currentPos = robotPos
        var direction = (-1, 0)
        var path = ""
        var visited = HashSet[(Int, Int)](currentPos)
        var countOnSameDirection = 0
        while ((scaffolds -- visited).size > 0) {
            var newPosition = applyDirection(currentPos, direction)
            if (scaffolds(newPosition)) {
                countOnSameDirection += 1
            } else {
                var potentialPositions = neighbours(currentPos).filter{ pos => !visited(pos) && scaffolds(pos) }
                newPosition = potentialPositions(0)
                val newDirection = computeNewDirection(currentPos, newPosition)
                path += f"$countOnSameDirection%02d" + computeTurning(direction, newDirection)
                direction = newDirection
                countOnSameDirection = 1
            }
            currentPos = newPosition
            visited += currentPos
        }
        path += f"$countOnSameDirection%02d"
        return path.drop(2)
    }
    def findRobotProgram(path: String): (String, Map[String, String]) = {
        var i = 40
        while (i > 4) {
            var (mainRoutine, functions) = findRobotProgram(path, 22, 'A', HashMap[String, String]())
            if (mainRoutine != "") {
                val realMainRoutine = mainRoutine.replace("AAAA", "A").replace("BBBB", "B").replace("CCCC", "C")
                val realFunctions = functions.map { case (k, v) => (k(0).toString, v) }
                return (realMainRoutine, realFunctions)
            }
        }
        return ("", HashMap[String, String]())
    }
    def findRobotProgram(mainRoutine: String, size: Int, fun: Char, functions: Map[String, String]): (String, Map[String, String]) = {
        if (fun == 'D' || size <= 4) { return (mainRoutine, functions) }
        val substrings = findRepeatingCode(mainRoutine, size)
        if (substrings.size > 0) {
            for ((pattern, _) <- substrings) {
                val functionName = s"$fun$fun$fun$fun"
                val (newMainRoutine, newFunctions) = findRobotProgram(
                    mainRoutine.replace(pattern, functionName),
                    size - 2,
                    (fun + 1).toChar,
                    functions + (functionName -> pattern)
                )
                if (newMainRoutine != "" && !newMainRoutine.contains("LL") && !newMainRoutine.contains("RR")) {
                    return (newMainRoutine, newFunctions)
                }
            }
            return ("", functions)
        } else {
            return findRobotProgram(mainRoutine, size - 2, fun, functions)
        }
    }
    def findRepeatingCode(mainRoutine: String, size: Int): Map[String, Int] = {
        var repeating = HashMap[String, Int]().withDefaultValue(0)
        for (i <- 0 until (mainRoutine.size - size) by 4) {
            val il = mainRoutine.slice(i, i + size)
            for (j <- (i + size) until (mainRoutine.size - size) by 4) {
                val jl = mainRoutine.slice(j, j + size)
                if (il == jl) {
                    repeating += (il -> (repeating(il) + 1))
                }
            }
        }
        return repeating
    }
    def sendRobotProgram(mainRoutine: String, functions: Map[String, String], program: String): Long = {
        val programToMoveRobot = IntcodeComputer(program)
        programToMoveRobot.codes(0) = 2
        programToMoveRobot.runProgram(List[Long]())
        var mainRoutineAscii = (mainRoutine.map{ c => List(c.toLong, ','.toLong) }.flatten.dropRight(1):+(10L)).toList
        var finalOutput = programToMoveRobot.runProgram(
            mainRoutineAscii 
            ++ functionToAscii(functions("A"))
            ++ functionToAscii(functions("B"))
            ++ functionToAscii(functions("C"))
            ++ List('n'.toLong, 10)
        )
        return finalOutput(finalOutput.size - 1)
    }
    def functionToAscii(functionString: String): List[Long] = {
        return (functionString.grouped(2).map { c => c match {
            case "LL" => List('L'.toLong, ','.toLong)
            case "RR" => List('R'.toLong, ','.toLong)
            case nrStr => nrStr.toInt.toString.map { _.toLong }:+(','.toLong)
        }}.toList.flatten.dropRight(1):+(10L)).toList
    }
}

class IntcodeComputer(var codes: Array[Long]) {
    var i: Int = 0
    var relative_base: Int = 0
    var halted: Boolean = false

    def runProgram(inputs: List[Long]): List[Long] = {
        var iterator = inputs.iterator
        var outputs = ListBuffer[Long]()
        while (!halted) {
            var (opcode, parameter_modes) = extract_opcode_and_parameter_modes(codes(i).toInt);
            var operand = ((offset: Int) => {
                parameter_modes(offset - 1) match {
                    case 0 => codes(codes(i + offset).toInt)
                    case 1 => codes(i + offset)
                    case 2 => codes(relative_base + codes(i + offset).toInt)
                    case n => throw new IllegalArgumentException(s"Operand parameter mode $n does not exist")
                }
            }): (Int => Long)
            var store = (offset: Int, value: Long) => {
                parameter_modes(offset - 1) match {
                    case 0 => codes(codes(i + offset).toInt) = value
                    case 2 => codes(relative_base + codes(i + offset).toInt) = value
                    case n => throw new IllegalArgumentException(s"Store parameter mode $n does not exist")
                }
            }
            opcode match {
                case 1 => { store(3, operand(1) + operand(2)); i += 4 }
                case 2 => { store(3, operand(1) * operand(2)); i += 4 }
                case 3 => { if (!iterator.hasNext) return outputs.toList; store(1, iterator.next()); i += 2 }
                case 4 => { outputs += operand(1); i += 2 }
                case 5 => i = if(operand(1) != 0) operand(2).toInt else i + 3
                case 6 => i = if(operand(1) == 0) operand(2).toInt else i + 3
                case 7 => { store(3, if(operand(1) < operand(2)) 1 else 0); i += 4 }
                case 8 => { store(3, if(operand(1) == operand(2)) 1 else 0); i += 4 }
                case 9 => { relative_base += operand(1).toInt; i += 2 }
                case 99 => halted = true
            }
        }
        return outputs.toList
    }

    private	def extract_opcode_and_parameter_modes(instruction: Int) = {
        (
            instruction % 100,
            List[Int](
                (instruction / 100) % 10,
                (instruction / 1000) % 10,
                (instruction / 10000) % 10,
            )
        )
    }
}

object IntcodeComputer {
    def apply(codes_str: String) = {
        val codesList: List[Long] = codes_str.split(",").map(x => x.toLong).toList
        val zeros = List.fill(10 * codesList.size)(0L)
        new IntcodeComputer((codesList ++ zeros).toArray)
    }

    def intcode_computer_tests() = {
		assert(IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8").runProgram(List(8L))(0) == 1)
		assert(IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8").runProgram(List(5L))(0) == 0)
		assert(IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8").runProgram(List(5L))(0) == 1)
		assert(IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8").runProgram(List(9L))(0) == 0)
		assert(IntcodeComputer("3,3,1108,-1,8,3,4,3,99").runProgram(List(8L))(0) == 1)
		assert(IntcodeComputer("3,3,1108,-1,8,3,4,3,99").runProgram(List(7L))(0) == 0)
		assert(IntcodeComputer("3,3,1107,-1,8,3,4,3,99").runProgram(List(3L))(0) == 1)
		assert(IntcodeComputer("3,3,1107,-1,8,3,4,3,99").runProgram(List(8L))(0) == 0)
		assert(IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9").runProgram(List(0L))(0) == 0)
		assert(IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9").runProgram(List(8L))(0) == 1)
		assert(IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1").runProgram(List(0L))(0) == 0)
		assert(IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1").runProgram(List(8L))(0) == 1)
		var codes = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99"
		assert(IntcodeComputer(codes).runProgram(List(5L))(0) == 999)
		assert(IntcodeComputer(codes).runProgram(List(8L))(0) == 1000)
		assert(IntcodeComputer(codes).runProgram(List(10L))(0) == 1001)
		var result = List(109L,1L,204L,-1L,1001L,100L,1L,100L,1008L,100L,16L,101L,1006L,101L,0L,99L)
		assert(IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99").runProgram(List[Long]()).equals(result))
		assert(IntcodeComputer("1102,34915192,34915192,7,4,7,99,0").runProgram(List[Long]())(0) == 1219070632396864L)
		assert(IntcodeComputer("104,1125899906842624,99").runProgram(List[Long]())(0) == 1125899906842624L)
	}
}