declare module "image-parser" {
    class Pixel {
        r: number;
        g: number;
        b: number;
        a: number;
    }

    class ImageParser {
        constructor(path: string);

        public parse(cb: (err: unknown) => void): void;
        public getPixel(x: number, y: number): Pixel;
        public pixels(): Pixel[];
        public width(): number;
        public height(): number;
        public save(path: string, cb: () => void);
    }

    export = ImageParser;
}