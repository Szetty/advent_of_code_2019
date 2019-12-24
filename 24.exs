#!/Users/arnold/.asdf/shims/elixir

defmodule Solver do
    def solve1(grid_str) do
        grid_str
        |> build_grid_map()
        |> simulate()
        |> biodiversity_rating()
    end

    def solve2(grid_str, minutes) do
        grid_str
        |> build_grid_map()
        |> Enum.into(%{}, fn {{x, y}, value} -> {{x, y, 0}, value} end)
        |> simulate_recursive(minutes)
        |> Enum.count()
    end

    defp build_grid_map(grid_str) do
        grid_str
        |> String.split("\n")
        |> Enum.map(&String.split(&1, "", trim: true))
        |> Enum.with_index()
        |> Enum.reduce(%{}, fn {line, y}, map -> 
            line
            |> Enum.with_index()
            |> Enum.reduce(map, fn {cell, x}, map ->
                Map.put(map, {x, y}, cell == "#")  
            end)
        end)
    end

    defp simulate(grid), do: simulate(grid, 0, MapSet.new())
    defp simulate(grid, minutes, previous_states) do
        if MapSet.member?(previous_states, grid) do
            grid
        else
            grid
            |> simulate_minute()
            |> simulate(minutes + 1, MapSet.put(previous_states, grid))
        end
    end

    defp simulate_minute(grid) do
        bug_count = fn {x, y} -> {x, y} |> neighbours() |> Enum.count(&Map.get(grid, &1, false)) end
        Enum.reduce(0..4, %{}, fn x, new_grid ->
            Enum.reduce(0..4, new_grid, fn y, new_grid ->
                value = Map.get(grid, {x, y}, false)
                bugs = bug_count.({x, y})
                Map.put(new_grid, {x, y}, transform_cell(value, bugs))
            end)  
        end)
    end

    defp biodiversity_rating(grid) do
        grid
        |> Enum.reduce(0, fn 
            {{x, y}, true}, sum -> sum + :math.pow(2, y * 5 + x) 
            _, sum -> sum       
        end)
        |> trunc()
    end

    defp simulate_recursive(grid, minutes), do: simulate_recursive(grid, 0, minutes)
    defp simulate_recursive(grid, minutes, minutes), do: grid
    defp simulate_recursive(grid, current_minutes, minutes) do
        grid
        |> simulate_minute_recursive()
        |> simulate_recursive(current_minutes + 1, minutes)
    end

    defp simulate_minute_recursive(grid) do
        neighbours = fn {x, y, level} ->
            neighbours_on_same_level = fn -> {x, y} |> neighbours() |> Enum.map(fn {x, y} -> {x, y, level} end) end
            case {x, y} do
                {2, 1} -> [{x + 1, y, level}, {x - 1, y, level}, {x, y - 1, level}] ++ Enum.map(0..4, &{&1, 0, level + 1})
                {1, 2} -> [{x, y + 1, level}, {x - 1, y, level}, {x, y - 1, level}] ++ Enum.map(0..4, &{0, &1, level + 1})
                {3, 2} -> [{x, y + 1, level}, {x + 1, y, level}, {x, y - 1, level}] ++ Enum.map(0..4, &{4, &1, level + 1})
                {2, 3} -> [{x, y + 1, level}, {x + 1, y, level}, {x - 1, y, level}] ++ Enum.map(0..4, &{&1, 4, level + 1})
                {0, 0} -> [{2, 1, level - 1}, {1, 2, level - 1}] ++ neighbours_on_same_level.()
                {4, 0} -> [{2, 1, level - 1}, {3, 2, level - 1}] ++ neighbours_on_same_level.()
                {0, 4} -> [{2, 3, level - 1}, {1, 2, level - 1}] ++ neighbours_on_same_level.()
                {4, 4} -> [{2, 3, level - 1}, {3, 2, level - 1}] ++ neighbours_on_same_level.()
                {0, _y} -> [{1, 2, level - 1}] ++ neighbours_on_same_level.()
                {4, _y} -> [{3, 2, level - 1}] ++ neighbours_on_same_level.()
                {_x, 0} -> [{2, 1, level - 1}] ++ neighbours_on_same_level.()
                {_x, 4} -> [{2, 3, level - 1}] ++ neighbours_on_same_level.()
                _ -> neighbours_on_same_level.()
            end
        end
        bugs_count = fn position -> position |> neighbours.() |> Enum.count(&Map.get(grid, &1, false)) end
        process_cell = fn cell, new_grid ->
            value = Map.get(grid, cell, false)
            bugs = bugs_count.(cell)
            new_value = transform_cell(value, bugs)
            if new_value, do: Map.put(new_grid, cell, true), else: new_grid
        end
        simulate_empty_level = fn level, positions -> Enum.reduce(positions, %{}, fn {x, y}, new_grid -> process_cell.({x, y, level}, new_grid) end) end
        {min_level, max_level} = grid |> Enum.map(fn {{_x, _y, level}, _value} -> level end) |> Enum.min_max()
        min_level..max_level
        |> Enum.reduce(%{}, fn level, new_grid ->
            Enum.reduce(0..4, new_grid, fn x, new_grid -> 
                Enum.reduce(0..4, new_grid, fn y, new_grid -> 
                    if x !== 2 || y !== 2, do: process_cell.({x, y, level}, new_grid), else: new_grid end
                )
            end)
        end)
        |> Map.merge(simulate_empty_level.(min_level - 1, [{2, 1}, {1, 2}, {3, 2}, {2, 3}]))
        |> Map.merge(simulate_empty_level.(max_level + 1, 0..4 |> Enum.map(fn z -> [{0, z}, {z, 0}, {4, z}, {z, 4}] end) |> List.flatten() |> Enum.uniq()))
    end

    defp neighbours({x, y}), do: [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]

    defp transform_cell(value, neighbour_bugs_count) do
        case {value, neighbour_bugs_count} do
            {true, bug_count} when bug_count != 1 -> false
            {false, bug_count} when bug_count in [1, 2] -> true
            {current, _} -> current
        end
    end
end

tests = fn ->
    test1 = File.read!("tests/24/1")
    if Solver.solve1(test1) != 2129920, do: raise "Test failed"
    if Solver.solve2(test1, 10) != 99, do: raise "Test failed"
end

tests.()
input = File.read!("inputs/24")
input |> Solver.solve1() |> IO.puts
input |> Solver.solve2(200) |> IO.puts