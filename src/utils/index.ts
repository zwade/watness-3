export const unreachable = (n: never): never => { throw new Error("Reached default case of exhaustive switch statement ")};

export type FilterKeys<K extends string | number | symbol> = K extends symbol ? never : K;
export type StringifyKeys<T extends {}> = `${FilterKeys<keyof T>}`;

export const keys = <T extends {}>(obj: T) => Object.keys(obj) as StringifyKeys<T>[]

export const objectMap = <U, V, T extends { [key: string]: U }>(obj: T, fn: (key: keyof T, value: U) => V): { [Key in keyof T]: V } => {
    return keys(obj)
        .reduce(
            (agg, key) => { agg[key] = fn(key, obj[key]); return agg },
            { } as { [Key in keyof T]: V }
        );
}

export const flatten = <T>(x: T[][]): T[] =>
    x.reduce((agg, v) => agg.concat(v), [] as T[]);

export const flatten3 = <T>(x: T[][][]): T[] =>
    flatten(x.map(flatten));