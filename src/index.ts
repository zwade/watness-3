import vertexSource from "./shaders/vertex.glsl";
import fragmentSource from "./shaders/watness.glsl";
import witnessImage from "./assets/the-witness.png";
import treeImage from "./assets/Tree.png";
import shrubImage from "./assets/Shrub.png"
import { decode } from "./utils/getFlag";
import { AttrKind, Faery, Triangles, WatnessCanvas } from "./webgl-utils";
import { AttribKind } from "./webgl-utils/geometry";
import { Program } from "./webgl-utils/program";
import { Texture } from "./webgl-utils/uniform";

const mouseSpeed = 0.002;
const TRUE:  [number, number, number, number] = [1, 0, 0, 0];
const FALSE: [number, number, number, number] = [0, 0, 0, 0];

const fromWTFloat = ([a, b, c]: [number, number, number, ...unknown[]]) => {
    return 2 * (a * 256 * 256 + b * 256 + c) / (256 * 256 * 256);
}

const toWTFloat = (x: number): [number, number, number, number] => {
    const bigboi = (x / 2) * 256 * 256 * 256;
    return [
        Math.floor(bigboi / (256 * 256)),
        Math.floor(bigboi % (256 * 256) / 256),
        Math.floor(bigboi % 256),
        0,
    ];
}

export const main = async () => {
    const canvas = new WatnessCanvas();

    const mainProgram = new Program(
        canvas,
        vertexSource.sourceCode,
        fragmentSource.sourceCode,
        {
            time: AttrKind.Float,
            dt: AttrKind.Float,
            resolution: AttrKind.Float2,
            loopback: AttrKind.Int4Vec,
            introImage: AttrKind.Texture,
            treeImage: AttrKind.Texture,
            shrubImage: AttrKind.Texture,
        },
        {
            time: 0,
            resolution: [canvas.width, canvas.height],
            introImage: new Texture(canvas.gl, 0, witnessImage),
            treeImage: new Texture(canvas.gl, 1, treeImage),
            shrubImage: new Texture(canvas.gl, 2, shrubImage),
        }
    );
    const fullScreen = new Triangles(
        mainProgram,
        { "myInput": AttribKind.Float3 },
        [[[-1, -1, 0], [1, -1, 0], [-1, 1, 0]], [[1, -1, 0], [1, 1, 0], [-1, 1, 0]]]
    );

    const faery = new Faery(canvas, mainProgram, fullScreen);
    canvas.draw();

    let previousTime = Date.now();
    let mouseDelta: [number, number] = [-1, -1];
    let loopback: [number, number, number, number][] = [];
    let keysDown = new Set<string>();
    let inCanvas = false;
    let click = false;
    let rightClick = false;
    let hasAlerted = false;

    canvas.on("active", () => {
        if (!inCanvas) {
            canvas.lockPointer();
            inCanvas = true;
        }
    })
    canvas.on("click", () => {
        click = true;
    });
    canvas.on("rightclick", () => {
        rightClick = true;
    });
    canvas.on("cursormove", (([dx, dy]) => {
        mouseDelta[0] += dx * mouseSpeed;
        mouseDelta[1] -= dy * mouseSpeed;
    }));
    canvas.on("keydown", (key) => keysDown.add(key));
    canvas.on("keyup", (key) => keysDown.delete(key));
    canvas.on("cursorexit", () => {
        keysDown = new Set();
        inCanvas = false;
    });

    const cb = (d: number) => {
        const events = Array.from(new Array(100), (): [number, number, number, number] => [0, 0, 0, 0]);
        const dt = d - previousTime;
        previousTime = d;

        events[10] = toWTFloat(mouseDelta[0] + 0.5);
        events[11] = toWTFloat(mouseDelta[1] + 0.5);

        mouseDelta = [0, 0];

        if (keysDown.has("ArrowUp")) {
            events[2] = TRUE;
        }
        if (keysDown.has("ArrowDown")) {
            events[3] = TRUE;
        }
        if (keysDown.has("ArrowLeft")) {
            events[0] = TRUE;
        }
        if (keysDown.has("ArrowRight")) {
            events[1] = TRUE;
        }

        events[4] = click ? TRUE : FALSE;
        click = false;

        events[5] = rightClick ? TRUE : FALSE;
        rightClick = false;

        mainProgram.set("dt", dt);
        mainProgram.set("time", d / 10000);
        mainProgram.set("loopback", loopback.concat(events));
        canvas.draw();

        loopback = canvas.readPixels(0, 0, 200);
        if (!hasAlerted && loopback[150][0]) {
            const rawKey = loopback
                .slice(130, 148)
                .map(([x]) => x);
            const result = decode(rawKey);
            console.log(result); // in case you miss it
            alert(result);
            hasAlerted = true;
        }
        requestAnimationFrame(cb);
    }
    requestAnimationFrame(cb);
}

window.addEventListener("load", main, false);
