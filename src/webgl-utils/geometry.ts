import { flatten, flatten3, keys, objectMap } from "../utils";
import { Program } from "./program";
import { WatnessCanvas } from "./watness-canvas";

export enum AttribKind {
    "Float",
    "Float2",
    "Float3",
    "Float4",
}

export type AttribKindToValue<T extends AttribKind> =
    | (AttribKind.Float extends T ? [number] : never)
    | (AttribKind.Float2 extends T ? [number, number] : never)
    | (AttribKind.Float3 extends T ? [number, number, number] : never)
    | (AttribKind.Float4 extends T ? [number, number, number, number]: never)

export type Attributes = { [K: string]: AttribKind };

export type AttribValues<T extends Attributes> =
    {
        [K in keyof T]: AttribKindToValue<T[K]>
    }


export type Point = [number, number, number];
export type Triangle = [Point, Point, Point];

export abstract class Geometry<T extends Attributes> {
    protected program;
    protected canvas;
    protected gl;
    protected primaryBuffer;
    protected attributes;
    protected buffers: { [Key in keyof T]: WebGLBuffer };

    protected abstract writeData(): void;
    public abstract render(): void;
    public abstract get dirty(): boolean;

    constructor(program: Program<any>, attributes: T) {
        this.program = program;
        this.canvas = program.canvas;
        this.gl = this.canvas.gl;
        this.primaryBuffer = this.canvas.gl.createBuffer();
        this.attributes = attributes;
        this.buffers = objectMap(this.attributes, () => this.gl.createBuffer()!);
    }

    public initialize() {
        this.gl.enableVertexAttribArray(0);
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.primaryBuffer);
        this.writeData();
    }

    public setBuffer<K extends keyof T>(name: K, value: AttribKindToValue<T[K]>[]) {
        const array = new Float32Array(flatten(value));
        const attribLocation = this.gl.getAttribLocation(this.program.program, name as string);

        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.buffers[name]);
        this.gl.bufferData(this.gl.ARRAY_BUFFER, array, this.gl.DYNAMIC_DRAW);

        this.gl.enableVertexAttribArray(attribLocation);
        this.gl.vertexAttribPointer(attribLocation, value[0].length, this.gl.FLOAT, false, 0, 0);
    }
}

export class Triangles<T extends Attributes> extends Geometry<T> {
    #dirty;
    private triangles;

    constructor(program: Program<any>, attributes: T, triangles: Triangle[]) {
        super(program, attributes);
        this.triangles = triangles;
        this.#dirty = true;
    }

    public writeData() {
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.primaryBuffer);
        this.gl.bufferData(
            this.gl.ARRAY_BUFFER,
            new Float32Array(flatten3(this.triangles)),
            this.gl.STATIC_DRAW
        );
        this.gl.vertexAttribPointer(0, 3, this.gl.FLOAT, false, 0, 0);
    }

    public render() {
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.primaryBuffer);
        this.gl.drawArrays(this.gl.TRIANGLES, 0, this.triangles.length * 3);
        this.#dirty = false;
    }

    public update(triangles: Triangle[]) {
        this.triangles = triangles;
        this.#dirty = true;
    }

    public get dirty() {
        return this.#dirty;
    }

}

