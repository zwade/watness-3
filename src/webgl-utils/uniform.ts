export class Texture {
    private url;
    private gl;

    public readonly texture;
    public readonly id;

    constructor(gl: WebGL2RenderingContext, id: number, url: string) {
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.RGBA,
            1, 1, 0,
            gl.RGBA, gl.UNSIGNED_BYTE,
            new Uint8Array([0, 0, 0, 0])
        );

        const image = new Image();
        image.onload = () => {
            gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        }
        image.src = url;

        this.gl = gl;
        this.url = url;
        this.texture = texture;
        this.id = id;
    }
}

export enum UniformKind {
    "Float",
    "Float2",
    "Int2",
    "Int2Vec",
    "Int4Vec",
    "Texture",
}

export type UniformKindToValue<T extends UniformKind> =
    | (UniformKind.Float extends T ? number : never)
    | (UniformKind.Float2 extends T ? [number, number] : never)
    | (UniformKind.Int2 extends T ? [number, number] : never)
    | (UniformKind.Int2Vec extends T ? [number, number][] : never)
    | (UniformKind.Int4Vec extends T ? [number, number, number, number][] : never)
    | (UniformKind.Texture extends T ? Texture : never)

export type Uniforms = { [K: string]: UniformKind };

export type UniformValues<T extends Uniforms> =
    {
        [K in keyof T]: UniformKindToValue<T[K]>
    }
