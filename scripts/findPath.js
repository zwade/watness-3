"use strict";
exports.__esModule = true;
var immutable_1 = require("immutable");
var ansi = {
    red: "\x1b[38;5;1m",
    green: "\x1b[38;5;2m",
    yellow: "\x1b[38;5;3m",
    blue: "\x1b[38;5;4m",
    purple: "\x1b[38;5;5m",
    clear: "\x1b[0m"
};
var colors = [ansi.red, ansi.green, ansi.yellow, ansi.blue, ansi.purple];
function modExp(b, e, m) {
    var base = b % m;
    var result = 1.0;
    for (var i = 0; i < 8; i++) {
        if (e % 2 == 1) {
            result = (result * base) % m;
        }
        base = (base * base) % m;
        e = Math.floor(e / 2.0);
    }
    return result;
}
function hash(value, maxVal, root) {
    var modRes = modExp(root, value, 4093.0);
    return Math.floor(modRes * maxVal / 4093.0);
}
function printGrid(grid) {
    for (var _i = 0, _a = grid.slice().reverse(); _i < _a.length; _i++) {
        var row = _a[_i];
        for (var _b = 0, row_1 = row; _b < row_1.length; _b++) {
            var value = row_1[_b];
            process.stdout.write(colors[value] + ("" + value).padEnd(3, " ") + ansi.clear);
        }
        process.stdout.write("\n");
    }
}
function createGrid(max, total, offset, hashRoot) {
    return Array.from(new Array(max), function (_, j) {
        return Array.from(new Array(max), function (_, i) { return (hash(j * max + i + offset, total, hashRoot)); });
    });
}
function dfs(grid, max) {
    var offsets = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    var dst = grid[0][0];
    var found = 0;
    var rec = function (queue, vals) {
        var _a = queue.slice(-1)[0], x = _a[0], y = _a[1];
        if (x === max - 1 && y === max - 1) {
            found++;
            return queue;
        }
        for (var i = 0; i < 4; i++) {
            var _b = offsets[i], dx = _b[0], dy = _b[1];
            var nx = x + dx;
            var ny = y + dy;
            var idx = ny * max + nx;
            if (nx < 0
                || nx >= max
                || ny < 0
                || ny >= max
                || vals.has(idx)
                || grid[ny][nx] !== dst)
                continue;
            var result = rec(queue.concat([[nx, ny]]), vals.add(idx));
            // if (result) return result;
        }
        return undefined;
    };
    rec([[0, 0]], immutable_1.Set([0]));
    return found;
}
for (var i = 0; i < 100; i++) {
    for (var r = 0; r < 100; r++) {
        var grid = createGrid(8, 2, i, 1000 + r);
        var result = dfs(grid, 8);
        if (result === 1) {
            printGrid(grid);
            console.log(i, r);
            // console.log(found);
            console.log(result);
        }
    }
}
