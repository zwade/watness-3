declare module "*.glsl" {
    import type { GlslShader } from "webpack-glsl-minify";

    const value: GlslShader;
    export default value;
}