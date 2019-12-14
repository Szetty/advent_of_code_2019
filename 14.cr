#!/usr/local/bin/crystal

def assertEqual(got, expected)
    if got != expected
        puts("Assertion error, got: #{got}, expected: #{expected}")
        Process.exit(0)
    end
end

def to_chemical(chemical_str)
    splits = chemical_str.split(" ")
    {splits[0].to_u64, splits[1]}
end

def build_reactions(reactions_str)
    f = ->to_chemical(String)
    reactions_str.lines.map do |line|
        splits = line.split(" => ")
        result_count, result_substance = f.call(splits[1])
        {result_substance, {result_count, splits[0].split(", ").map(&f)}}
    end.to_h
end

def simulate_reactions(reactions, fuel_count)
    q = Deque.new([{fuel_count, reactions["FUEL"][1]}])
    supply = {} of String => UInt64
    ore_count = 0_u64
    while q.size > 0
        count, reactants = q.shift
        next if count == 0
        (ore_count += count * reactants[0][0]; next) if reactants.size == 1 && reactants[0][1] == "ORE"
        reactants.each do |reactant_count, substance|
            count_produced, new_reactants = reactions[substance]
            count_needed = count * reactant_count
            leftover = supply.fetch(substance, 0_u64)
            if leftover < count_needed
                div, mod = (count_needed - leftover).divmod(count_produced)
                div += 1 if mod > 0
                supply[substance] = (count_produced - mod) % count_produced
                q.push({div, new_reactants})
            else
                supply[substance] = leftover - count_needed
            end
        end
    end
    ore_count
end

def solve1(reactions_str) simulate_reactions(build_reactions(reactions_str), 1_u64) end

def binary_search(evaluator, l, h, expected_result)
    while l != h - 1
        middle = (l + h) // 2
        l, h = evaluator.call(middle) <= expected_result ? {middle, h} : {l, middle}
    end
    l
end

def solve2(reactions_str, ore_supply_count)
    reactions = build_reactions(reactions_str)
    predicted_fuel = ore_supply_count // simulate_reactions(reactions, 1_u64)
    evaluator = ->(fuel : UInt64) { simulate_reactions(reactions, fuel) }
    binary_search(evaluator, predicted_fuel, predicted_fuel * 2, ore_supply_count)
end

def run_tests()
    assertEqual(solve1(File.read("tests/14/1")), 31)
    assertEqual(solve1(File.read("tests/14/2")), 165)
    [{3, 13312, 82892753}, {4, 180697, 5586022}, {5, 2210736, 460664}].each { |test_id, output1, output2| 
        input = File.read("tests/14/#{test_id}")
        assertEqual(solve1(input), output1)
        assertEqual(solve2(input, 1_000_000_000_000_u64), output2)
    }
end

run_tests()
reactions_str = File.read("inputs/14")
puts(solve1(reactions_str))
puts(solve2(reactions_str, 1_000_000_000_000_u64))