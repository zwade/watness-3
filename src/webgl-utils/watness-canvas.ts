import { EventManager } from "./event-manager";
import { Faery } from "./faery";

type WatnessEvents = {
    "active": {},
    "canvasmove": [x: number, y: number],
    "click": [x: number, y: number],
    "rightclick": [x: number, y: number],
    "cursormove": [dx: number, dy: number],
    "cursorexit": {},
    "keydown": string,
    "keyup": string,
}

export class WatnessCanvas extends EventManager<WatnessEvents> {
    private canvas;
    private fae;

    public gl;

    constructor(selector = "canvas") {
        super();
        const canvas = document.querySelector(selector) as HTMLCanvasElement | null;
        if (!canvas) {
            throw new Error("Could not initialize canvas");
        }
        this.fae = [] as Faery[]
        this.canvas = canvas;
        this.gl = this.initializeContext(canvas);
        this.initializeEvents();
    }

    public draw() {
        for (let faery of this.fae) {
            if (faery.program.dirty || faery.geometry.dirty) {
                faery.program.renderGeometry(faery.geometry);
            }
        }
    }

    public register(faery: Faery) {
        this.fae.push(faery);
    }

    public deregister(faery: Faery) {
        const index = this.fae.indexOf(faery);
        if (index < 0) {
            return;
        }

        this.fae = this.fae.slice(0, index).concat(this.fae.slice(index + 1));
    }

    public readPixels(x = 0, y = 0, width = 20, height = 1) {
        const pixels = new Uint8Array(width * height * 4);
        this.gl.readPixels(x, y, width, height, this.gl.RGBA, this.gl.UNSIGNED_BYTE, pixels);
        return Array.from(new Array(width * height), (_, i) =>
            Array.from(pixels.slice(i * 4, (i + 1) * 4)) as [number, number, number, number]
        )
    }

    public lockPointer() {
        this.canvas.requestPointerLock();
    }

    public releasePointer() {
        document.exitPointerLock();
    }

    public get width() {
        return this.canvas.width;
    }

    public get height() {
        return this.canvas.height;
    }

    private initializeContext(canvas: HTMLCanvasElement) {
        canvas.width = this.canvas.clientWidth;
        canvas.height = this.canvas.clientHeight;

        const gl = canvas.getContext("webgl2");
        if (!gl) {
            throw new Error("Failed to get WebGL context")
        }

        gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
        gl.clearColor(0, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);
        return gl;
    }

    private initializeEvents() {
        const getMouseLocation = (evt: MouseEvent): [x: number, y: number] => {
            const bound = this.canvas.getBoundingClientRect();

            const x = evt.clientX - bound.left - this.canvas.clientLeft;
            const y = evt.clientY - bound.top - this.canvas.clientTop;

            return [x, this.canvas.clientHeight - y];
        }

        this.canvas.addEventListener("mousemove", (evt) => {
            this.fire("canvasmove", getMouseLocation(evt))
        });

        this.canvas.addEventListener("click", (evt) => {
            this.fire("active", {});
        });

        const onRightClick = (evt: MouseEvent) => {
            if (evt.button === 0) {
                this.fire("click", getMouseLocation(evt));
            } else if (evt.button === 2) {
                this.fire("rightclick", getMouseLocation(evt));
            }
            evt.preventDefault();
        }

        const onCursorMove = (evt: MouseEvent) => {
            this.fire("cursormove", [evt.movementX, evt.movementY]);
        }

        const onKeyDown = (evt: KeyboardEvent) => {
            this.fire("keydown", evt.code);
            evt.preventDefault();
        }

        const onKeyUp = (evt: KeyboardEvent) => {
            this.fire("keyup", evt.code);
            evt.preventDefault();
        }

        document.addEventListener("pointerlockchange", (evt) => {
            if (document.pointerLockElement === this.canvas) {
                document.addEventListener("mousemove", onCursorMove);
                document.addEventListener("keydown", onKeyDown);
                document.addEventListener("keyup", onKeyUp);
                document.addEventListener("mousedown", onRightClick);
            } else {
                document.removeEventListener("mousemove", onCursorMove);
                document.removeEventListener("keydown", onKeyDown);
                document.removeEventListener("keyup", onKeyUp);
                document.removeEventListener("mousedown", onRightClick);
                this.fire("cursorexit", {});
            }
        });
    }
}