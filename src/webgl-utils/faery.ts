import { Geometry } from "./geometry";
import { Program } from "./program";

import type { WatnessCanvas } from "./watness-canvas";

export class Faery {
    private canvas;

    public program;
    public geometry;

    constructor(canvas: WatnessCanvas, program: Program<any>, geometry: Geometry<any>) {
        this.canvas = canvas;

        this.program = program as Program<never>;
        this.geometry = geometry as Geometry<never>;

        this.canvas.register(this);
    }

    public destroy() {
        this.canvas.deregister(this);
        this.program.destroy();
    }
}