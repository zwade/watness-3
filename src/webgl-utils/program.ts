import { Geometry } from "./geometry";
import { UniformKind, UniformKindToValue, Uniforms, UniformValues } from "./uniform";
import { flatten, unreachable } from "../utils";
import { WatnessCanvas } from "./watness-canvas";

export class Program<T extends Uniforms> {
    #dirty;

    private attrs;
    private values: Partial<UniformValues<T>>;
    public readonly gl;
    public readonly canvas;
    public readonly program;

    constructor(
        canvas: WatnessCanvas,
        vertexSource: string,
        fragmentSource: string,
        attrs: T,
        values?: Partial<UniformValues<T>>,
    ) {
        const gl = canvas.gl;

        const vertexShader = gl.createShader(gl.VERTEX_SHADER)!;
        gl.shaderSource(vertexShader, vertexSource);
        gl.compileShader(vertexShader);
        if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) {
            throw new Error(gl.getShaderInfoLog(vertexShader)!);
        }

        const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)!;
        gl.shaderSource(fragmentShader, fragmentSource);
        gl.compileShader(fragmentShader);
        if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) {
            throw new Error(gl.getShaderInfoLog(fragmentShader)!);
        }

        const program = gl.createProgram()!;

        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            const linkErrLog = [gl.getShaderInfoLog(vertexShader),  gl.getShaderInfoLog(fragmentShader), gl.getProgramInfoLog(program)];
            throw ("ERROR:\n" +
                "VALIDATE_STATUS: " + gl.getProgramParameter(program, gl.VALIDATE_STATUS) + "\n" +
                "ERROR: " + linkErrLog + "\n\n")
        }
        gl.detachShader(program, vertexShader);
        gl.detachShader(program, fragmentShader);
        gl.deleteShader(vertexShader);
        gl.deleteShader(fragmentShader);

        this.attrs = attrs;
        this.values = values ?? {};
        this.canvas = canvas;
        this.gl = gl;
        this.program = program;
        this.#dirty = true;
    }

    public use(fn: (gl: WebGL2RenderingContext) => void) {
        this.gl.useProgram(this.program);
        fn(this.gl);
    }

    public renderGeometry(geometry: Geometry<never>) {
        this.use(() => {
            geometry.initialize();
            for (let name in this.values) {
                this.bindAttr(name, this.attrs[name], this.values[name]!);
            }
            geometry.render();
        });
        this.#dirty = false;
    }

    public set<K extends keyof T>(name: K, value: UniformKindToValue<T[K]>) {
        this.values[name] = value;
        this.#dirty = true;
    }

    public destroy() {
        this.gl.useProgram(null);
        this.gl.deleteProgram(this.program);
    }

    public get dirty() {
        return this.#dirty;
    }

    private bindAttr<U extends UniformKind>(name: string, kind: U, attr: UniformKindToValue<U>) {
        switch (kind) {
            case UniformKind.Float: {
                const a = attr as UniformKindToValue<UniformKind.Float>;
                this.gl.uniform1f(
                    this.gl.getUniformLocation(this.program, name),
                    a
                );
                break;
            }
            case UniformKind.Float2: {
                const a = attr as UniformKindToValue<UniformKind.Float2>;
                this.gl.uniform2f(
                    this.gl.getUniformLocation(this.program, name),
                    a[0], a[1]
                );
                break;
            }
            case UniformKind.Int2: {
                const a = attr as UniformKindToValue<UniformKind.Int2>;
                this.gl.uniform2i(
                    this.gl.getUniformLocation(this.program, name),
                    a[0], a[1],
                );
                break;
            }
            case UniformKind.Int2Vec: {
                const a = attr as UniformKindToValue<UniformKind.Int2Vec>;
                this.gl.uniform2iv(
                    this.gl.getUniformLocation(this.program, name),
                    new Int32Array(flatten(a))
                );
                break;
            }
            case UniformKind.Int4Vec: {
                const a = attr as UniformKindToValue<UniformKind.Int4Vec>;
                this.gl.uniform4iv(
                    this.gl.getUniformLocation(this.program, name),
                    new Int32Array(flatten(a))
                );
                break;
            }
            case UniformKind.Texture: {
                const a = attr as UniformKindToValue<UniformKind.Texture>;
                this.gl.activeTexture(this.gl[`TEXTURE${a.id}` as "TEXTURE0"]);
                this.gl.bindTexture(this.gl.TEXTURE_2D, a.texture);
                this.gl.uniform1i(
                    this.gl.getUniformLocation(this.program, name),
                    a.id
                );
                break;
            }
        }
    }

}