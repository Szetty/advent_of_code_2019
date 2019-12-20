#!/Users/arnold/.asdf/shims/ts-node
import * as fs from 'fs'
import * as assert from 'assert'

type Portal = string;
class Coord { 
    x: number
    y: number
    constructor(x: number, y: number) { this.x = x; this.y = y }
    toString(): string { return `${this.x},${this.y}` }
    static fromString(str: string): Coord {
        const [x, y] = str.split(',')
        return new Coord(parseInt(x), parseInt(y))
    }
    equals(otherCoord: Coord) { return this.x == otherCoord.x && this.y == otherCoord.y }
}
type CoordPair = Record<string, Coord>
enum CoordType { Empty, Open, Wall }
interface Maze {
    grid: CoordType[][]
    portalCoords: Record<Portal, CoordPair>
    portalsByCoord: Record<string, Portal>
    portalTypes: Record<string, PortalType>
    startingCoord: Coord
    finishingCoord: Coord
}
enum PortalType { Inc = 1, Dec = -1 }
class Coord3d {
    coord: Coord
    level: number
    constructor(coord: Coord, level: number) { this.coord = coord; this.level = level }
    toString(): string { return this.coord.toString() + `@${this.level}`}
    static fromString(str: string): Coord3d {
        const [coordS, levelS] = str.split('@')
        return new Coord3d(Coord.fromString(coordS), parseInt(levelS))
    }
    withX(x: number) { return new Coord3d(new Coord(x, this.coord.y), this.level)}
    withY(y: number) { return new Coord3d(new Coord(this.coord.x, y), this.level)}
    withLevel(level: number) { return new Coord3d(new Coord(this.coord.x, this.coord.y), level)}
    equals(otherCoord: Coord3d) { return this.coord.equals(otherCoord.coord) && this.level == otherCoord.level}
}
class MazeParser {
    static emptyCoord = new Coord(-1, -1)
    static parseInput(input: string): Maze {
        const lines = input.split('\n')
        const rows = lines.length
        const columns = lines[0].length
        const maze = {
            grid: new Array(columns - 4).fill([]).map(() => new Array(rows - 4).fill(CoordType.Empty)),
            portalCoords: {},
            portalsByCoord: {},
            portalTypes: {},
            startingCoord: this.emptyCoord,
            finishingCoord: this.emptyCoord,
        }
        this.findPortalsOnEdges(maze, lines)
        for (let y = 2; y < rows - 2; y++) {
            for (let x = 2; x < columns - 2; x++) {
                switch (lines[y][x]) { 
                    case '#': { maze.grid[x - 2][y - 2] = CoordType.Wall; break; }
                    case '.': { maze.grid[x - 2][y - 2] = CoordType.Open; break; }
                    case ' ': { break; }
                    default: {
                        const letter1 = lines[y][x]
                        if (lines[y + 1][x] != ' ' && lines[y + 1][x] != '.') {
                            const v = lines[y - 1][x]
                            this.addPortal(maze, letter1, lines[y + 1][x], x, v == '.' ? y - 1 : y + 2, PortalType.Inc)
                        }
                        if (lines[y][x + 1] != ' ' && lines[y][x + 1] != '.') {
                            const v = lines[y][x - 1]
                            this.addPortal(maze, letter1, lines[y][x + 1], v == '.' ? x - 1 : x + 2, y, PortalType.Inc)
                        }
                        break;
                    } 
                } 
            }
        }
        return maze
    }
    static findPortalsOnEdges(maze: Maze, lines: string[]): void {
        const rows = lines.length
        const columns = lines[0].length
        for (let x = 0; x < columns; x++) {
            if (lines[0][x] != ' ') { this.addPortal(maze, lines[0][x], lines[1][x], x, 2, PortalType.Dec) }
            if (lines[rows - 2][x] != ' ') { this.addPortal(maze, lines[rows - 2][x], lines[rows - 1][x], x, rows - 3, PortalType.Dec) }
        }
        for (let y = 0; y < rows; y++) {
            if (lines[y][0] != ' ') { this.addPortal(maze, lines[y][0], lines[y][1], 2, y, PortalType.Dec) }
            if (lines[y][columns - 2] != ' ') { this.addPortal(maze, lines[y][columns - 2], lines[y][columns - 1], columns - 3, y, PortalType.Dec) }
        }
    }
    static addPortal(maze: Maze, letter1: string, letter2: string, x: number, y: number, type: PortalType): void {
        const coord = new Coord(x - 2, y - 2)
        const portal = `${letter1}${letter2}` as Portal
        if (portal == 'AA') { maze.startingCoord = coord }
        else if (portal == 'ZZ') { maze.finishingCoord = coord }
        else if (!maze.portalsByCoord[coord.toString()]) {
            if (maze.portalCoords[portal]) {
                const portalMap = maze.portalCoords[portal]
                const otherCoord = portalMap[this.emptyCoord.toString()]
                delete portalMap[this.emptyCoord.toString()]
                portalMap[coord.toString()] = otherCoord
                portalMap[otherCoord.toString()] = coord
            } else {
                maze.portalCoords[portal] = {[this.emptyCoord.toString()]: coord}
            }
            maze.portalsByCoord[coord.toString()] = portal
            maze.portalTypes[coord.toString()] = type
        }
    }
}
class Solver1 {
    static solve(maze: Maze): number {
        const lastCoord = maze.finishingCoord
        let currentCoords = new Set<string>([maze.startingCoord.toString()])
        const visited = new Set<string>([maze.startingCoord.toString()])
        let steps = 1
        while (true) {
            let newCurrentCoords = new Set<string>()
            for (const currentCoord of Array.from(currentCoords)) {
                const coords = this.nextCoords(maze, Coord.fromString(currentCoord), visited)
                if (coords.some(coord => coord.equals(lastCoord))) { return steps }
                coords.forEach(c => {
                    visited.add(c.toString())
                    newCurrentCoords.add(c.toString())
                })
            }
            currentCoords = newCurrentCoords
            steps++
        }
    }
    static nextCoords(maze: Maze, currentCoord: Coord, visited: Set<string>): Coord[] {
        const portal = maze.portalsByCoord[currentCoord.toString()]
        return this.neighbours(currentCoord)
            .filter(({x, y}) => (maze.grid[x] || [])[y] == CoordType.Open && !visited.has(new Coord(x, y).toString()))
            .concat(
                portal ? [maze.portalCoords[portal][currentCoord.toString()]] : []
            )
    }
    static neighbours({x, y}): Coord[] {
        return [new Coord(x + 1, y), new Coord(x - 1, y), new Coord(x, y + 1), new Coord(x, y - 1)]
    }
    static tests() {
        assert(this.solve(MazeParser.parseInput(fs.readFileSync('tests/20/1', 'utf8'))) == 23)
        assert(this.solve(MazeParser.parseInput(fs.readFileSync('tests/20/2', 'utf8'))) == 58)
    }
}

class Solver2 {
    static solve(maze: Maze): number {
        const lastCoord = new Coord3d(maze.finishingCoord, 0)
        const startCoord = new Coord3d(maze.startingCoord, 0)
        let currentCoords = new Set<string>([startCoord.toString()])
        const visited = new Set<string>([startCoord.toString()])
        let steps = 1
        while (currentCoords.size > 0) {
            let newCurrentCoords = new Set<string>()
            for (const currentCoord of Array.from(currentCoords)) {
                const coords = this.nextCoords(maze, Coord3d.fromString(currentCoord), visited)
                if (coords.some(coord => coord.equals(lastCoord))) { return steps }
                coords.forEach(c => { visited.add(c.toString()); newCurrentCoords.add(c.toString()) })
            }
            currentCoords = newCurrentCoords
            steps++
        }
        return 0
    }
    static nextCoords(maze: Maze, currentCoord: Coord3d, visited: Set<string>): Coord3d[] {
        const portal = maze.portalsByCoord[currentCoord.coord.toString()]
        return this.neighbours(currentCoord)
            .filter((coord: Coord3d) => {
                const {coord: {x, y}} = coord
                return (maze.grid[x] || [])[y] == CoordType.Open && !visited.has(coord.toString())
            })
            .concat(
                portal && this.isPortalOnCurrentLevel(maze, currentCoord) ? [this.goThroughPortal(maze, portal, currentCoord)] : []
            )
    }
    static neighbours(coord: Coord3d): Coord3d[] {
        const {coord: {x, y}} = coord
        return [coord.withX(x + 1), coord.withX(x - 1), coord.withY(y + 1), coord.withY(y - 1)]
    }
    static isPortalOnCurrentLevel(maze: Maze, currentCoord: Coord3d) {
        return currentCoord.level != 0 || maze.portalTypes[currentCoord.coord.toString()] == PortalType.Inc
    }
    static goThroughPortal(maze: Maze, portal: Portal, currentCoord: Coord3d): Coord3d {
        const coord2d = maze.portalCoords[portal][currentCoord.coord.toString()]
        const level: number = currentCoord.level + maze.portalTypes[currentCoord.coord.toString()]
        return new Coord3d(coord2d, level)
    }
    static tests() {
        assert(this.solve(MazeParser.parseInput(fs.readFileSync('tests/20/1', 'utf8'))) == 26)
        assert(this.solve(MazeParser.parseInput(fs.readFileSync('tests/20/3', 'utf8'))) == 396)
    }
}

Solver1.tests()
Solver2.tests()
const maze = MazeParser.parseInput(fs.readFileSync('inputs/20', 'utf8'))
console.log(Solver1.solve(maze))
console.log(Solver2.solve(maze))