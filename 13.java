
// run with Java 13
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.stream.Collectors;

class Main {
	public static void main(String[] args) {
		try {
			intcode_computer_tests();
			var program = new String(Files.readAllBytes(Paths.get("inputs/13")));
			System.out.println(solve1(program));
			System.out.println(solve2(program));
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}

	private static int solve1(String program) {
		var computer = new IntcodeComputer(program);
		var outputs = computer.run_program(new ArrayList<>());
		var blocks = 0;
		for (var i = 2; i < outputs.size(); i += 3) {
			if (outputs.get(i).intValue() == 2) {
				blocks++;
			}
		}
		return blocks;
	}

	private static int solve2(String program) {
		var computer = new IntcodeComputer(program);
		computer.codes[0] = 2L;
		var gameState = buildGameState(computer.run_program(new ArrayList<>()));
		updateGameState(gameState, computer.run_program(Arrays.asList(0L)));
		while (!computer.halted && gameState.blocks.size() > 0) {
			long move = Integer.compare(gameState.ballPosition.x, gameState.paddlePosition.x);
			updateGameState(gameState, computer.run_program(Arrays.asList(move)));
		}
		return gameState.score;
	}

	private static GameState buildGameState(List<Long> values) {
		int maxX = 0;
		for (var i = 0; i < values.size(); i += 3) {
			var x = values.get(i).intValue();
			if (x > maxX) {
				maxX = x;
			}
		}
		int maxY = 0;
		for (var i = 1; i < values.size(); i += 3) {
			var y = values.get(i).intValue();
			if (y > maxY) {
				maxY = y;
			}
		}
		var grid = new ObjectType[maxY + 1][];
		for (var y = 0; y <= maxY; y++) {
			grid[y] = new ObjectType[maxX + 1];
		}
		var gameState = new GameState(grid);
		updateGameState(gameState, values);
		return gameState;
	}

	private static void updateGameState(GameState gameState, List<Long> values) {
		for (var i = 0; i < values.size(); i += 3) {
			var x = values.get(i).intValue();
			var y = values.get(i + 1).intValue();
			var type = values.get(i + 2).intValue();
			if (x == -1 && y == 0) {
				gameState.score = type;
			} else {
				switch (type) {
					case 0:
						gameState.grid[y][x] = ObjectType.Empty;
						gameState.blocks.remove(new Point(x, y));
						break;
					case 1:
						gameState.grid[y][x] = ObjectType.Wall;
						break;
					case 2:
						gameState.grid[y][x] = ObjectType.Block;
						gameState.blocks.add(new Point(x, y));
						break;
					case 3:
						gameState.grid[y][x] = ObjectType.Paddle;
						gameState.paddlePosition = new Point(x, y);
						break;
					case 4:
						gameState.grid[y][x] = ObjectType.Ball;
						gameState.ballPosition = new Point(x, y);
						break;
				}
			}
		}
	}

	private static void printGameState(GameState gameState) {
		for (var y = 0; y < gameState.grid.length; y++) {
			for (var x = 0; x < gameState.grid[y].length; x++) {
				System.out.print(gameState.grid[y][x].draw);
			}
			System.out.println();
		}
	}

	static class GameState {
		public ObjectType[][] grid;
		public int score;
		public Point ballPosition;
		public Point paddlePosition;
		public Set<Point> blocks = new HashSet<>();
		public GameState(ObjectType[][] grid) { this.grid = grid; }
	}

	static enum ObjectType { 
		Empty(" "), Wall("#"), Block("+"), Paddle("⚝"), Ball("*");
		public String draw;
		private ObjectType(String draw) { this.draw = draw; } 
	}

	static class Point {
		private int x;
		private int y;
		public Point(int x, int y) { this.x = x; this.y = y; }
		public boolean equals(Object o) {
			if (o == this) return true;
			if (!(o instanceof Point)) return false;
			Point point = (Point) o;
			return x == point.x && y == point.y;
		}
		public int hashCode() { return Objects.hash(x, y); }
	}

	static class IntcodeComputer {
		public Long[] codes;
		public int i;
		public int relative_base;
		public boolean halted;
	
		public IntcodeComputer(String codes_str) {
			var codesList = Arrays.stream(codes_str.split(",")).map(Long::valueOf).collect(Collectors.toList());
			codesList.addAll(Collections.nCopies(10 * codesList.size(), 0L));
			codes = codesList.toArray(new Long[0]);
			i = relative_base = 0;
			halted = false;
		}
	
		public List<Long> run_program(List<Long> inputs) {
			var iterator = inputs.iterator();
			List<Long> outputs = new ArrayList<>();
			while (true) {
				int[] parameter_modes = new int[3];
				var opcode = extract_opcode_and_parameter_modes(codes[i].intValue(), parameter_modes);
				Function<Integer, Long> operand = (Integer offset) -> {
					switch(parameter_modes[offset - 1]) {
						case 0: return codes[codes[i + offset].intValue()];
						case 1: return codes[i + offset];
						case 2: return codes[relative_base + codes[i + offset].intValue()];
						default: throw new IllegalArgumentException(String.format("Operand parameter mode %d does not exist", parameter_modes[offset - 1]));
					}
				};
				BiConsumer<Integer, Long> store = (Integer offset, Long value) -> { 
					switch(parameter_modes[offset - 1]) {
						case 0: codes[codes[i + offset].intValue()] = value; break;
						case 2: codes[relative_base + codes[i + offset].intValue()] = value; break;
						default: throw new IllegalArgumentException(String.format("Store parameter mode %d does not exist", parameter_modes[offset - 1]));
					}
				};
				switch (opcode) {
					case 1:
						store.accept(3, operand.apply(1) + operand.apply(2));
						i += 4;
						break;
					case 2:
						store.accept(3, operand.apply(1) * operand.apply(2));
						i += 4;
						break;
					case 3:
						if (!iterator.hasNext()) return outputs;
						store.accept(1, iterator.next());
						i += 2;
						break;
					case 4:
						outputs.add(operand.apply(1));
						i += 2;
						break;
					case 5:
						i = (operand.apply(1) != 0 ? operand.apply(2).intValue() : i + 3);
						break;
					case 6:
						i = (operand.apply(1) == 0 ? operand.apply(2).intValue() : i + 3);
						break;
					case 7:
						store.accept(3, Long.valueOf(operand.apply(1) < operand.apply(2) ? 1 : 0));
						i += 4;
						break;
					case 8:
						store.accept(3, Long.valueOf(operand.apply(1).longValue() == operand.apply(2).longValue() ? 1 : 0));
						i += 4;
						break;
					case 9:
						relative_base += operand.apply(1);
						i += 2;
						break;
					case 99:
						halted = true;
						return outputs;
				}
			}
		}

		private	int extract_opcode_and_parameter_modes(int instruction, int[] parameter_modes) {
			parameter_modes[0] = (instruction / 100) % 10;
			parameter_modes[1] = (instruction / 1000) % 10;
			parameter_modes[2] = (instruction / 10000) % 10;
			return instruction % 100;
		}
	}

	private static void intcode_computer_tests() {
		assert (new IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8")).run_program(Arrays.asList(8L)).get(0).intValue() == 1;
		assert (new IntcodeComputer("3,9,8,9,10,9,4,9,99,-1,8")).run_program(Arrays.asList(5L)).get(0).intValue() == 0;
		assert (new IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8")).run_program(Arrays.asList(5L)).get(0).intValue() == 1;
		assert (new IntcodeComputer("3,9,7,9,10,9,4,9,99,-1,8")).run_program(Arrays.asList(9L)).get(0).intValue() == 0;
		assert (new IntcodeComputer("3,3,1108,-1,8,3,4,3,99")).run_program(Arrays.asList(8L)).get(0).intValue() == 1;
		assert (new IntcodeComputer("3,3,1108,-1,8,3,4,3,99")).run_program(Arrays.asList(7L)).get(0).intValue() == 0;
		assert (new IntcodeComputer("3,3,1107,-1,8,3,4,3,99")).run_program(Arrays.asList(3L)).get(0).intValue() == 1;
		assert (new IntcodeComputer("3,3,1107,-1,8,3,4,3,99")).run_program(Arrays.asList(8L)).get(0).intValue() == 0;
		assert (new IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")).run_program(Arrays.asList(0L)).get(0).intValue() == 0;
		assert (new IntcodeComputer("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")).run_program(Arrays.asList(8L)).get(0).intValue() == 1;
		assert (new IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")).run_program(Arrays.asList(0L)).get(0).intValue() == 0;
		assert (new IntcodeComputer("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")).run_program(Arrays.asList(8L)).get(0).intValue() == 1;
		var codes = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";
		assert new IntcodeComputer(codes).run_program(Arrays.asList(5L)).get(0).intValue() == 999;
		assert new IntcodeComputer(codes).run_program(Arrays.asList(8L)).get(0).intValue() == 1000;
		assert new IntcodeComputer(codes).run_program(Arrays.asList(10L)).get(0).intValue() == 1001;
		List<Long> result = Arrays.asList(109L,1L,204L,-1L,1001L,100L,1L,100L,1008L,100L,16L,101L,1006L,101L,0L,99L);
		assert (new IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99")).run_program(new ArrayList<>()).equals(result);
		assert (new IntcodeComputer("1102,34915192,34915192,7,4,7,99,0")).run_program(new ArrayList<>()).get(0).longValue() == 1219070632396864L;
		assert (new IntcodeComputer("104,1125899906842624,99")).run_program(new ArrayList<>()).get(0).longValue() == 1125899906842624L;
	}
}
