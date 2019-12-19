class IntcodeComputer {
    public Long[] codes;
    public int i = 0;
    public int relative_base = 0;
    public boolean halted = false;

    IntcodeComputer(String codes_str) {
        def codesList = codes_str.split(",").collect{ Long.valueOf(it) };
        codesList.addAll(Collections.nCopies(10 * codesList.size(), 0L));
        codes = codesList.toArray(new Long[0]);
    }

    public List<Long> run_program(List<Long> inputs) {
        def iterator = inputs.iterator();
        List<Long> outputs = new ArrayList<>();
        while (!halted) {
            int[] parameter_modes = new int[3];
            def opcode = extract_opcode_and_parameter_modes(codes[i].intValue(), parameter_modes);
            def operand = { Integer offset ->
                switch(parameter_modes[offset - 1]) {
                    case 0: return codes[codes[i + offset].intValue()];
                    case 1: return codes[i + offset];
                    case 2: return codes[relative_base + codes[i + offset].intValue()];
                    default: throw new IllegalArgumentException(String.format("Operand parameter mode %d does not exist", parameter_modes[offset - 1]));
                }
            };
            def store = { Integer offset, Long value -> 
                switch(parameter_modes[offset - 1]) {
                    case 0: codes[codes[i + offset].intValue()] = value; break;
                    case 2: codes[relative_base + codes[i + offset].intValue()] = value; break;
                    default: throw new IllegalArgumentException(String.format("Store parameter mode %d does not exist", parameter_modes[offset - 1]));
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
                    if (!iterator.hasNext()) return outputs;
                    store(1, iterator.next());
                    i += 2;
                    break;
                case 4:
                    outputs.add(operand(1));
                    i += 2;
                    break;
                case 5:
                    i = (operand(1) != 0 ? operand(2).intValue() : i + 3);
                    break;
                case 6:
                    i = (operand(1) == 0 ? operand(2).intValue() : i + 3);
                    break;
                case 7:
                    store(3, Long.valueOf(operand(1) < operand(2) ? 1 : 0));
                    i += 4;
                    break;
                case 8:
                    store(3, Long.valueOf(operand(1).longValue() == operand(2).longValue() ? 1 : 0));
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

    private	int extract_opcode_and_parameter_modes(int instruction, int[] parameter_modes) {
        parameter_modes[0] = (instruction.intdiv(100)) % 10;
        parameter_modes[1] = (instruction.intdiv(1000)) % 10;
        parameter_modes[2] = (instruction.intdiv(10000)) % 10;
        return instruction % 100;
    }

    public static void intcode_computer_tests() {
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
		def codes = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";
		assert new IntcodeComputer(codes).run_program(Arrays.asList(5L)).get(0).intValue() == 999;
		assert new IntcodeComputer(codes).run_program(Arrays.asList(8L)).get(0).intValue() == 1000;
		assert new IntcodeComputer(codes).run_program(Arrays.asList(10L)).get(0).intValue() == 1001;
		List<Long> result = Arrays.asList(109L,1L,204L,-1L,1001L,100L,1L,100L,1008L,100L,16L,101L,1006L,101L,0L,99L);
		assert (new IntcodeComputer("109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99")).run_program(new ArrayList<>()).equals(result);
		assert (new IntcodeComputer("1102,34915192,34915192,7,4,7,99,0")).run_program(new ArrayList<>()).get(0).longValue() == 1219070632396864L;
		assert (new IntcodeComputer("104,1125899906842624,99")).run_program(new ArrayList<>()).get(0).longValue() == 1125899906842624L;
	}
}

def runIntcodeProgram(program, x, y) { new IntcodeComputer(program).run_program(Arrays.asList(x, y))[0] }

def solve1 = { program -> (0..49).inject(0) { sx, x -> sx + (0..49).inject(0) { sy, y -> sy + runIntcodeProgram(program, x, y) } } }

def are_enough_elements(range, jranges, iranges, elements_needed) {
    def last_irange = iranges[range[-1]]
    if (last_irange[1] - last_irange[0] < elements_needed) { 
        return false 
    }
    for (entry in jranges) {
        def jrange = entry.value
        if (jrange[1] - jrange[0] >= elements_needed) {
            return true
        }
    }
    return false
}

def printGrid = { grid, range -> range.each { i -> range.each {j -> print (grid[i] ?: [])[j] ?: "."}; println() } }

def searchForClosestPoint(range, xranges, yranges, elements_needed) {
    def max_y = range[-1]
    def max_x = yranges.keySet().max()
    for (x in 0..max_x) {
        if (yranges[x][1] - yranges[x][0] >= elements_needed) {
            for (y in 0..max_y) {
                if (xranges[y][1] - x >= elements_needed && yranges[x][1] - y >= elements_needed) { return [x, y] }
            }
        }
    }
    return null
}

def solve2(program) {
    def grid = []
    def xranges = [(-1): [0]]
    def yranges = [:]
    def range = 0..500
    def elements_needed = 99
    while (true) {
        for (y in range) {
            def found = false
            for (x in xranges[y - 1][0]..(range[-1])) {
                def result = runIntcodeProgram(program, x, y)
                if (!found && result == 1) {
                    found = true
                    xranges[y] = [x]
                    if (!yranges[x]) { yranges[x] = [y, y] } else { yranges[x][-1] = y }
                }
                if (found && result == 0) {
                    xranges[y][1] = (x - 1)
                    break 
                }
                if (result == 1) {
                    if (!grid[x]) { grid[x] = [] }
                    grid[x][y] = '#'
                    if (!yranges[x]) { yranges[x] = [y, y] } else { yranges[x][-1] = y }
                }
            }
            if (!found) { xranges[y] = xranges[y - 1] }
        }
        if (are_enough_elements(range, yranges, xranges, elements_needed)) {
            def closestPoint = searchForClosestPoint(range, xranges, yranges, elements_needed)
            if (closestPoint) {
                def (x, y) = closestPoint
                return x * 10000 + y
            }
            range = (range[-1] + 1)..(range[-1] + 100)
        } else {
            range = (range[-1] + 1)..(range[-1] + 500)
        }
    }
}

IntcodeComputer.intcode_computer_tests()
def program = new File('inputs/19').text
println(solve1(program))
println(solve2(program))