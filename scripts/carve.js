"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
var fs = require("fs-extra");
var pngjs_1 = require("pngjs");
var puzzleWidth = 8;
var puzzleHeight = 8;
var desiredPath = [];
var permutation = function (n) {
    var base = Array.from(new Array(n), function (_, i) { return i; });
    for (var i = 1; i < n; i++) {
        var prev = Math.floor(Math.random() * (i - 1));
        base[i] = base[prev];
        base[prev] = i;
    }
    return base;
};
var generatePath = function (minLength) {
    var visited = new Map([[0, new Set([0])]]);
    var offsets = [[0, 1], [0, -1], [1, 0], [-1, 0]];
    var recurse = function (queue) {
        var _a;
        var _b = queue.slice(-1)[0], x = _b[0], y = _b[1];
        if (x === puzzleWidth - 1 && y === puzzleHeight - 1 && queue.length >= minLength) {
            return [true, queue];
        }
        for (var _i = 0, _c = permutation(4); _i < _c.length; _i++) {
            var idx = _c[_i];
            var _d = offsets[idx], dx = _d[0], dy = _d[1];
            var nx = dx + x;
            var ny = dy + y;
            var foundSet = (_a = visited.get(nx)) !== null && _a !== void 0 ? _a : new Set();
            if (foundSet.has(ny) || nx < 0 || nx >= puzzleWidth || ny < 0 || ny >= puzzleHeight) {
                continue;
            }
            else {
                foundSet.add(ny);
                visited.set(nx, foundSet);
            }
            var result_1 = recurse(queue.concat([[nx, ny]]));
            if (result_1[0]) {
                return result_1;
            }
        }
        return [false];
    };
    var result = recurse([[0, 0]]);
    if (result[0]) {
        return result[1];
    }
    throw new Error("Could not generate path");
};
var main = function () { return __awaiter(void 0, void 0, void 0, function () {
    var path, data, image, i, px, py, y, x, nx, ny, distance;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                path = generatePath(25);
                return [4 /*yield*/, fs.writeFile("./path.json", JSON.stringify(path))];
            case 1:
                _a.sent();
                return [4 /*yield*/, fs.readFile("./the-witness.png")];
            case 2:
                data = _a.sent();
                return [4 /*yield*/, new Promise(function (resolve) {
                        var img = new pngjs_1.PNG().parse(data, function () { return resolve(img); });
                    })];
            case 3:
                image = _a.sent();
                for (i = 0; i < path.length - 1; i++) {
                    px = (path[i][0] + path[i + 1][0]) / (2 * puzzleWidth);
                    py = (path[i][1] + path[i + 1][1]) / (2 * puzzleHeight);
                    for (y = 0; y < image.height; y++) {
                        for (x = 0; x < image.width; x++) {
                            nx = x / image.width;
                            ny = y / image.height;
                            distance = Math.sqrt(Math.sqrt(Math.pow((nx - px), 2) + Math.pow((ny - py), 2)));
                            if (distance < 0.08) {
                                image.data[(y * image.width + x) * 4 + 3] = 254;
                            }
                        }
                    }
                }
                image.pack().pipe(fs.createWriteStream("../src/assets/the-witness.png"));
                return [2 /*return*/];
        }
    });
}); };
main();
