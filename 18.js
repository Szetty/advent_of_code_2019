#!/Users/arnold/.asdf/shims/node
const fs = require('fs')
const Graph = require('@dagrejs/graphlib').Graph;
const SortedSet = require("collections/sorted-set");
const assert = require('assert');

const positionToId = ([i, j]) => `${i},${j}`
const idToPosition = (str) => str.split(',').map(x => parseInt(x))
const neighbours = ([i, j]) => [[i + 1, j], [i - 1, j], [i, j + 1], [i, j - 1]]
const isKey = (value) => /[a-z]/.test(value)
const isDoor = (value) => /[A-Z]/.test(value)
const isAccessible = (value) => isKey(value) || isDoor(value) || value == '.'
const initialize = (gridString) => {
    const grid = gridString.split('\n').map((line) => line.split(''))
    grid.c = ([i, j]) => grid[i][j]
    const startPosition = grid.reduce((pos, line, i) => {
        const j = line.findIndex(cell => cell == '@')
        return (pos == null && j != -1) ? [i, j] : pos
    }, null)
    return [grid, startPosition]
}
const buildPathGraph = (grid, startPosition) => {
    const buildGraph = (grid, graph, currentPosition, keys, doors) => {
        const currentCell = grid.c(currentPosition)
        if (isKey(currentCell)) { keys[positionToId(currentPosition)] = currentCell }
        if (isDoor(currentCell)) { doors[positionToId(currentPosition)] = currentCell.toLowerCase() }
        const nextPositions = neighbours(currentPosition).filter(pos => isAccessible(grid.c(pos)) && !graph.node(positionToId(pos)))
        for (const nextPosition of nextPositions) {
            graph.setNode(positionToId(nextPosition), [])
            graph.setEdge(positionToId(currentPosition), positionToId(nextPosition), 1)
            buildGraph(grid, graph, nextPosition, keys, doors)
        }
    }
    const graph = new Graph()
    graph.setNode(positionToId(startPosition), [])
    const keys = {}
    const doors = {}
    buildGraph(grid, graph, startPosition, keys, doors)
    return {
        graph: graph,
        keys: keys,
        doors: doors
    }
}
const stateToId1 = ({position, keysFound}) => `${positionToId(position)}!${keysFound.toArray().join('')}`
const nextStates1 = ({position, keysFound}, graph, keys, doors, visited) => {
    const positionId = positionToId(position)
    return graph.nodeEdges(positionId)
        .map(edge => {
            const posId = edge.v == positionId ? edge.w : edge.v
            const key = keys[posId]
            const isKey = key && !keysFound.has(key)
            const state = {
                positionId: posId,
                position: idToPosition(posId),
                keysFound: isKey ? keysFound.union([key]) : keysFound
            }
            return {...state, id: stateToId1(state)}
        })
        .filter(({id, positionId}) => {
            const door = doors[positionId]
            return (!door || keysFound.has(door)) && !visited.has(id)
        })
}
const findShortestPath1 = ({graph, keys, doors}, startPosition) => {
    const keysNr = Object.keys(keys).length
    const firstState = {position: startPosition, keysFound: SortedSet([])}
    let states = [firstState]
    let steps = 0
    let lastLength = 0
    const visited = new Set([stateToId1(firstState)])
    while (states.length > 0) {
        if (states.some(({keysFound}) => keysFound.length == keysNr)) { return steps }
        if (states.every(({keysFound}) => keysFound.length > lastLength)) {
            lastLength++
            visited.forEach((stateId) => {
                if((stateId.split("!")[1] || []).length < lastLength) {
                    visited.delete(stateId)
                }
            })
        }
        const newStates = []
        for (const state of states) {
            nextStates1(state, graph, keys, doors, visited).forEach(state => {
                visited.add(state.id)
                newStates.push(state)
            })
        }
        states = newStates
        steps++
    }
    return Infinity
}
const solve1 = (gridString) => {
    const [grid, startPosition] = initialize(gridString)
    const pathGraph = buildPathGraph(grid, startPosition)
    return findShortestPath1(pathGraph, startPosition)
}
const stateToId2 = ({positions, keysFound, blocked}) => {
    const positionsStr = positions.map((position) => positionToId(position)).join('#')
    const blockedStr = blocked.map((value) => value ? value : '0').join('')
    const keysFoundStr = keysFound.toArray().join('')
    return `${positionsStr}X${blockedStr}!${keysFoundStr}`
}
const nextPositions = (position, graph) => {
    const positionId = positionToId(position)
    return graph.nodeEdges(positionId)
        .map(edge => {
            const posId = edge.v == positionId ? edge.w : edge.v
            return {
                positionId: posId,
                position: idToPosition(posId)
            }
        })
}
const nextStates2 = (pathGraphs, positions, keysFound, visited, blocked, i) => {
    if (i >= pathGraphs.length) { return [] }
    if (blocked[i] || SortedSet(Object.values(pathGraphs[i].keys)).difference(keysFound).length == 0) { 
        return nextStates2(pathGraphs, positions, keysFound, visited, blocked, i + 1)
    }
    const position = positions[i]
    const {graph, keys, doors} = pathGraphs[i]
    return nextPositions(position, graph)
        .map(({positionId, position}) => {
            const key = keys[positionId]
            const door = doors[positionId]
            const isKey = key && !keysFound.has(key)
            let newBlocked = blocked
            if (isKey) {
                newBlocked = blocked.map((blockingDoor) => blockingDoor == key ? false : blockingDoor)
            }
            let newPositions = [...positions]
            if (!door || keysFound.has(door)) {
                newPositions[i] = position
                const state = {
                    positions: newPositions,
                    keysFound: isKey ? keysFound.union([key]) : keysFound,
                    blocked: newBlocked
                }
                return {...state, id: stateToId2(state)}
            } else {
                const newBlocked = [...blocked]
                newBlocked[i] = door
                return nextStates2(pathGraphs, positions, keysFound, visited, newBlocked, i + 1)
            }
        })
        .flat()
        .filter((state) => state && state != [] && !visited.has(state.id))
}
const findShortestPath2 = (pathGraphs, startPositions) => {
    const keysNr = pathGraphs.reduce((sum, {keys}) => sum + Object.keys(keys).length, 0)
    let states = [{ positions: startPositions, keysFound: SortedSet([]), blocked: new Array(pathGraphs.length).fill(false) }]
    let steps = 0
    let lastLength = 0
    const visited = new Set()
    visited.add(stateToId2(states[0]))
    while (states.length > 0) {
        if (states.some(({keysFound}) => keysFound.length == keysNr)) { return steps }
        if (states.every(({keysFound}) => keysFound.length > lastLength)) {
            lastLength++
            visited.forEach((stateId) => {
                if((stateId.split("!")[1] || []).length < lastLength) {
                    visited.delete(stateId)
                }
            })
        }
        const newStates = []
        for (const state of states) {
            const {positions, keysFound, blocked} = state
            nextStates2(pathGraphs, positions, keysFound, visited, blocked, 0).forEach(state => {
                visited.add(state.id)
                newStates.push(state)
            })
        }
        states = newStates
        steps++
    }
    return Infinity
}
const replaceStart = (grid, [i, j]) => {
    grid[i - 1][j - 1] = "@"
    grid[i - 1][j] = "#"
    grid[i - 1][j + 1] = "@"
    grid[i][j - 1] = "#"
    grid[i][j] = "#"
    grid[i][j + 1] = "#"
    grid[i + 1][j - 1] = "@"
    grid[i + 1][j] = "#"
    grid[i + 1][j + 1] = "@"
    return [[i - 1, j - 1], [i - 1, j + 1], [i + 1, j - 1], [i + 1, j + 1]]
}
const solve2 = (gridString) => {
    const [grid, startPosition] = initialize(gridString)
    const startPositions = replaceStart(grid, startPosition)
    const pathGraphs = startPositions.map(startPosition => buildPathGraph(grid, startPosition))
    return findShortestPath2(pathGraphs, startPositions)
}
const tests = () => {
    assert(solve1(fs.readFileSync('tests/18/1', 'utf8')) == 8)
    assert(solve1(fs.readFileSync('tests/18/2', 'utf8')) == 86)
    assert(solve1(fs.readFileSync('tests/18/3', 'utf8')) == 132)
    assert(solve1(fs.readFileSync('tests/18/4', 'utf8')) == 136)
    assert(solve1(fs.readFileSync('tests/18/5', 'utf8')) == 81)
    assert(solve2(fs.readFileSync('tests/18/6', 'utf8')) == 8)
    assert(solve2(fs.readFileSync('tests/18/7', 'utf8')) == 24)
    assert(solve2(fs.readFileSync('tests/18/8', 'utf8')) == 32)
    assert(solve2(fs.readFileSync('tests/18/9', 'utf8')) == 72)
}

tests()
const input = fs.readFileSync('inputs/18', 'utf8')
console.log(solve1(input))
console.log(solve2(input))