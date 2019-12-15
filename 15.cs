// compiled using csc from mono, and run with mono
#define TRACE
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.IO;
using System.Text;
using System.Threading;

public class Run
{
    private static List<Point> MOVES = new List<Point>{new Point(0, 1), new Point(0, -1), new Point(-1, 0), new Point(1, 0)};
    public static void Main(string[] args)
    {
        IntcodeComputer.IntcodeComputerTests();
        string program = File.ReadAllText(@"inputs/15", Encoding.UTF8);
        Console.WriteLine(Solve1(program));
        Console.WriteLine(Solve2(program));
    }

    private static int Solve1(string program) {
        var computer = new IntcodeComputer(program);
        var output = -1;
        var current = new Point(0, 0);
        var path = new Stack<Point>(new List<Point>{current});
        var visited = new HashSet<Point>(new List<Point>{current});
        while(output != 2) {
            var nextMoves = new Stack<Point>(MOVES.FindAll(move => !visited.Contains(current + move)));
            while (nextMoves.Count > 0) {
                var nextMove = nextMoves.Pop();
                output = (int) computer.RunProgram(new List<long>{MOVES.IndexOf(nextMove) + 1})[0];
                var nextPosition = current + nextMove;
                visited.Add(nextPosition);
                if (output != 0) {
                    path.Push(nextPosition);
                    current = nextPosition;
                    break;
                }
            }
            if (output == 0) {
                path.Pop();
                var new_current = path.Peek();
                var move = MOVES.IndexOf(new_current - current) + 1;
                computer.RunProgram(new List<long>{move});
                current = new_current;
            }
        }
        return path.Count - 1;
    }

    private static int Solve2(string program) {
        var map = ExploreMap(program);
        PrintMap(map);
        var source = map.First((keyValuePair) => keyValuePair.Value.Equals(LocationType.OXYGEN)).Key;
        return MaxDistanceToAnyEmptyLocation(map, source);
    }

    private static Dictionary<Point, LocationType> ExploreMap(string program) {
        var computer = new IntcodeComputer(program);
        var output = -1;
        var current = new Point(0, 0);
        var path = new Stack<Point>(new List<Point>{current});
        var visited = new HashSet<Point>(new List<Point>{current});
        var map = new Dictionary<Point, LocationType>();
        map.Add(new Point(0, 0), LocationType.EMPTY);
        while(path.Count > 0) {
            var nextMoves = new Stack<Point>(MOVES.FindAll(move => !visited.Contains(current + move)));
            while (nextMoves.Count > 0) {
                var nextMove = nextMoves.Pop();
                output = (int) computer.RunProgram(new List<long>{MOVES.IndexOf(nextMove) + 1})[0];
                var nextPosition = current + nextMove;
                visited.Add(nextPosition);
                switch (output) {
                    case 0: map.Add(nextPosition, LocationType.WALL); break;
                    case 1: map.Add(nextPosition, LocationType.EMPTY); break;
                    case 2: map.Add(nextPosition, LocationType.OXYGEN); break;
                }
                if (output != 0) {
                    path.Push(nextPosition);
                    current = nextPosition;
                    break;
                }
            }
            if (output == 0 && path.Count > 0) {
                path.Pop();
                if (path.Count > 0) {
                    var new_current = path.Peek();
                    var move = MOVES.IndexOf(new_current - current) + 1;
                    computer.RunProgram(new List<long>{move});
                    current = new_current;
                }
            }
        }
        return map;
    }

    private static void PrintMap(Dictionary<Point, LocationType> map) {
        var xs = map.Keys.Select(p => p.x);
        var min_x = xs.Min();
        var max_x = xs.Max();
        var ys = map.Keys.Select(p => p.y);
        var min_y = ys.Min();
        var max_y = ys.Max();
        for (var j = min_y; j <= max_y; j++) {
            for (var i = min_x; i <= max_x; i++) {
                Console.Write(map.GetValueOrDefault(new Point(i, j), LocationType.UNKNOWN).Value);
            }
            Console.WriteLine();
        }
    }

    private static int MaxDistanceToAnyEmptyLocation(Dictionary<Point, LocationType> map, Point source) {
        var distances = new Dictionary<Point, int>();
        var currentPoints = new HashSet<Point>(new List<Point>{source});
        var currentDistance = 0;
        var visited = new HashSet<Point>();
        while(currentPoints.Count > 0) {
            var newCurrentPoints = new HashSet<Point>();
            foreach (var point in currentPoints) {
                visited.Add(point);
                distances[point] = currentDistance;
                newCurrentPoints.UnionWith(
                    MOVES
                    .Select(move => point + move)
                    .Where(dest => map[dest].Equals(LocationType.EMPTY) && !visited.Contains(dest))
                    .ToHashSet()
                );
            }
            currentPoints = newCurrentPoints;
            currentDistance++;
        }
        return distances.Values.Max();
    }
}

public struct Point
{
    public int x;
    public int y;
    public Point(int x, int y)
    {
        this.x = x;
        this.y = y;
    }
    public static Point operator +(Point lhs, Point rhs) => new Point{ x = lhs.x + rhs.x, y = lhs.y + rhs.y };
    public static Point operator -(Point lhs, Point rhs) => new Point{ x = lhs.x - rhs.x, y = lhs.y - rhs.y };
    public override string ToString() { return "(" + x + " " + y + ")"; }
}

public class LocationType
{
    private LocationType(string value) { Value = value; }
    public string Value { get; set; }
    public static LocationType OXYGEN { get { return new LocationType("O"); } }
    public static LocationType WALL { get { return new LocationType("#"); } }
    public static LocationType EMPTY { get { return new LocationType("."); } }
    public static LocationType UNKNOWN { get { return new LocationType(" "); } }
    public override bool Equals(object obj) { if (obj == null) { return false; } return this.Value.Equals((obj as LocationType).Value); }
    public override int GetHashCode() { return this.Value.GetHashCode(); }
}

public class IntcodeComputer 
{
    public long[] codes;
    public int i;
    public int relative_base;
    public bool halted;

    public IntcodeComputer(string codes_str) {
        var codesEnum = codes_str.Split(",").Select(long.Parse);
        codes = Enumerable.Concat<long>(codesEnum, Enumerable.Repeat(0L, 10 * codesEnum.Count())).ToArray();    
        i = relative_base = 0;
        halted = false;
    }

    public IList<long> RunProgram(IList<long> inputs) {
        var iterator = inputs.GetEnumerator();
        var outputs = new List<long>();
        while (true) {
            int[] parameter_modes = new int[3];
            var opcode = ExtractOpcodeAndParameterModes((int) codes[i], parameter_modes);
            Func<int, long> operand = (int offset) => {
                switch(parameter_modes[offset - 1]) {
                    case 0: return codes[codes[i + offset]];
                    case 1: return codes[i + offset];
                    case 2: return codes[relative_base + codes[i + offset]];
                    default: throw new System.ArgumentException(string.Format("Operand parameter mode {0} does not exist", parameter_modes[offset - 1]));
                }
            };
            Action<int, long> store = (int offset, long value) => { 
                switch(parameter_modes[offset - 1]) {
                    case 0: codes[codes[i + offset]] = value; break;
                    case 2: codes[relative_base + codes[i + offset]] = value; break;
                    default: throw new System.ArgumentException(string.Format("Store parameter mode {0} does not exist", parameter_modes[offset - 1]));
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
                    if (!iterator.MoveNext()) return outputs;
                    store(1, iterator.Current);
                    i += 2;
                    break;
                case 4:
                    outputs.Add(operand(1));
                    i += 2;
                    break;
                case 5:
                    i = (operand(1) != 0 ? (int) operand(2) : i + 3);
                    break;
                case 6:
                    i = (operand(1) == 0 ? (int) operand(2) : i + 3);
                    break;
                case 7:
                    store(3, (operand(1) < operand(2) ? 1 : 0));
                    i += 4;
                    break;
                case 8:
                    store(3, (operand(1) == operand(2)? 1 : 0));
                    i += 4;
                    break;
                case 9:
                    relative_base += (int) operand(1);
                    i += 2;
                    break;
                case 99:
                    halted = true;
                    return outputs;
            }
        }
    }

    private	int ExtractOpcodeAndParameterModes(int instruction, int[] parameter_modes) {
        parameter_modes[0] = (instruction / 100) % 10;
        parameter_modes[1] = (instruction / 1000) % 10;
        parameter_modes[2] = (instruction / 10000) % 10;
        return instruction % 100;
    }

    public static void IntcodeComputerTests() {
		Trace.Assert((new IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8")).RunProgram(new List<long>{8})[0] == 1);
		Trace.Assert((new IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8")).RunProgram(new List<long>{5})[0] == 0);
		Trace.Assert((new IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8")).RunProgram(new List<long>{5})[0] == 1);
		Trace.Assert((new IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8")).RunProgram(new List<long>{9})[0] == 0);
		Trace.Assert((new IntcodeComputer("3,3,1108,-1,8,3,4,3,99")).RunProgram(new List<long>{8})[0] == 1);
		Trace.Assert((new IntcodeComputer("3,3,1108,-1,8,3,4,3,99")).RunProgram(new List<long>{7})[0] == 0);
		Trace.Assert((new IntcodeComputer("3,3,1107,-1,8,3,4,3,99")).RunProgram(new List<long>{3})[0] == 1);
		Trace.Assert((new IntcodeComputer("3,3,1107,-1,8,3,4,3,99")).RunProgram(new List<long>{8})[0] == 0);
		Trace.Assert((new IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")).RunProgram(new List<long>{0})[0] == 0);
		Trace.Assert((new IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")).RunProgram(new List<long>{8})[0] == 1);
		Trace.Assert((new IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")).RunProgram(new List<long>{0})[0] == 0);
		Trace.Assert((new IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")).RunProgram(new List<long>{8})[0] == 1);
		var codes = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";
		Trace.Assert(new IntcodeComputer(codes).RunProgram(new List<long>{5})[0] == 999);
		Trace.Assert(new IntcodeComputer(codes).RunProgram(new List<long>{8})[0] == 1000);
		Trace.Assert(new IntcodeComputer(codes).RunProgram(new List<long>{10})[0] == 1001);
		var expected = new List<long>{109L,1L,204L,-1L,1001L,100L,1L,100L,1008L,100L,16L,101L,1006L,101L,0L,99L};
        var got = new IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99").RunProgram(new List<long>());
		Trace.Assert(Enumerable.SequenceEqual(expected, got));
		Trace.Assert((new IntcodeComputer("1102,34915192,34915192,7,4,7,99,0")).RunProgram(new List<long>())[0] == 1219070632396864L);
		Trace.Assert((new IntcodeComputer("104,1125899906842624,99")).RunProgram(new List<long>())[0] == 1125899906842624L);
	}
}