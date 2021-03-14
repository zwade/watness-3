import { Set } from "immutable";

const ansi = {
    red: "\x1b[38;5;1m",
    green: "\x1b[38;5;2m",
    yellow: "\x1b[38;5;3m",
    blue: "\x1b[38;5;4m",
    purple: "\x1b[38;5;5m",

    clear: "\x1b[0m",
}

const colors = [ansi.red, ansi.green, ansi.yellow, ansi.blue, ansi.purple];

function modExp (b: number, e: number, m: number) {
    let base = b % m;
    let result = 1.0;
    for (let i = 0; i < 8; i++) {
        if (e % 2 == 1) {
            result = (result * base) % m;
        }
        base = (base * base) % m;
        e = Math.floor(e / 2.0);
    }
    return result;
}

function hash(value: number, maxVal: number, root: number) {
    const modRes = modExp(root, value, 4093.0);
    return Math.floor(modRes * maxVal / 4093.0);
}

function printGrid(grid: number[][]) {
    for (let row of grid.slice().reverse()) {
        for (let value of row) {
            process.stdout.write(colors[value] + `${value}`.padEnd(3, " ") + ansi.clear)
        }
        process.stdout.write("\n");
    }
}

function createGrid(max: number, total: number, offset: number, hashRoot: number) {
    return Array.from(new Array(max), (_, j) =>
        Array.from(new Array(max), (_, i) => (
            hash(j * max + i + offset, total, hashRoot)
        ))
    );
}

function dfs(grid: number[][], max: number) {
    const offsets = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    const dst = grid[0][0];

    let found = 0;

    const rec = (queue: [number, number][], vals: Set<number>): [number, number][] | undefined => {
        const [x, y] = queue.slice(-1)[0];
        if (x === max - 1 && y === max - 1) {
            found++;
            return queue;
        }

        for (let i = 0; i < 4; i++) {
            const [dx, dy] = offsets[i];
            let nx = x + dx;
            let ny = y + dy;

            const idx = ny * max + nx;
            if (
                nx < 0
                || nx >= max
                || ny < 0
                || ny >= max
                || vals.has(idx)
                || grid[ny][nx] !== dst
            ) continue;

            const result = rec(queue.concat([[nx, ny]]), vals.add(idx));
            // if (result) return result;
        }

        return undefined;
    }

    rec([[0, 0]], Set([0]))
    return found;
}

for (let i = 0; i < 100; i ++) {
    for (let r = 0; r < 100; r++) {
        const grid = createGrid(8, 2, i, 1000 + r);
        const result = dfs(grid, 8);
        if (result === 1) {
            printGrid(grid);
            console.log(i, r);
            // console.log(found);
            console.log(result);
        }
    }
}