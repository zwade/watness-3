import * as fs from "fs-extra";
import * as jpg from "jpeg-js";
import { number } from "mathjs";

const puzzleWidth = 8;
const puzzleHeight = 8;

const desiredPath: [number, number][] = [];

const permutation = (n: number) => {
    const base = Array.from(new Array(n), (_, i) => i);
    for (let i = 1; i < n; i++) {
        const prev = Math.floor(Math.random() * (i - 1));
        base[i] = base[prev];
        base[prev] = i;
    }

    return base;
}

const generatePath = (minLength: number) => {
    const visited = new Map<number, Set<number>>();
    const offsets: [number, number][] = [[0, 1], [0, -1], [1, 0], [-1, 0]];

    const recurse = (queue: [number, number][]): [true, [number, number][]] | [false] => {
        console.log(queue);
        const [x, y] = queue.slice(-1)[0];
        if (x !== puzzleWidth - 1 && y !== puzzleHeight - 1 && queue.length >= minLength) {
            return [true, queue];
        }

        for (let idx of permutation(4)) {
            const [dx, dy] = offsets[idx];
            const nx = dx + x;
            const ny = dy + y;

            const foundSet = visited.get(nx) ?? new Set();
            if (foundSet.has(ny) || nx < 0 || nx >= puzzleWidth || ny < 0 || ny >= puzzleHeight) {
                continue;
            } else {
                foundSet.add(ny);
                visited.set(nx, foundSet);
            }

            const result = recurse(queue.concat([[nx, ny]]));
            if (result[0]) {
                return result;
            }
        }

        return [false];
    }

    const result = recurse([[0, 0]]);
    if (result[0]) {
        return result[1];
    }

    throw new Error("Could not generate path");
}

const main = async () => {
    // const path = generatePath(25);
    // await fs.writeFile("./path.json", JSON.stringify(path));
    const path = JSON.parse((await fs.readFile("./path.json")).toString());

    const data = await fs.readFile("./the-witness.jpg");
    const image = jpg.decode(data);

    for (let y = 0; y < image.height; y++) {
        for (let x = 0; x < image.width; x++) {
            for (let i = 0; i < path.length - 1; i++) {
                const nx = x / image.width;
                const ny = y / image.height;
                const px = (path[i][0] + path[i+1][0]) / (2 * puzzleWidth);
                const py = (path[i][1] + path[i+1][1]) / (2 * puzzleHeight);
                const distance = Math.sqrt(Math.sqrt((nx - px) ** 2 + (ny - py) ** 2));

                image.data[(y * image.width + x) * 4 + 3] = 0;
                if (distance < 1) {
                }
            }
        }
    }

    const encoded = jpg.encode(image);
    await fs.writeFile("./the-witness.out.jpg", encoded.data);
}

main();