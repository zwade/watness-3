export enum UniformKind {
    "Float",
    "Float2",
    "Int2",
    "Int2Vec",
    "Int4Vec",
}

export type UniformKindToValue<T extends UniformKind> =
    | (UniformKind.Float extends T ? number : never)
    | (UniformKind.Float2 extends T ? [number, number] : never)
    | (UniformKind.Int2 extends T ? [number, number] : never)
    | (UniformKind.Int2Vec extends T ? [number, number][] : never)
    | (UniformKind.Int4Vec extends T ? [number, number, number, number][] : never)

export type Uniforms = { [K: string]: UniformKind };

export type UniformValues<T extends Uniforms> =
    {
        [K in keyof T]: UniformKindToValue<T[K]>
    }
