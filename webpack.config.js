const path = require("path");

const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
    mode: process.env.MODE ?? "development",

    // Enable sourcemaps for debugging webpack's output.
    devtool: process.env.MODE === "production" ? undefined : "source-map",

    resolve: {
        // Add '.ts' and '.tsx' as resolvable extensions.
        extensions: [".ts", ".js", ".scss", ".css", ".glsl"]
    },

    devServer: {
        host: "0.0.0.0",
        port: "5500",
        hot: true,
        historyApiFallback: true,
    },

    output: {
        publicPath: "/",
    },

    module: {
        rules: [{
                test: /\.ts$/,
                exclude: /node_modules/,
                use: [{
                    loader: "ts-loader"
                }]
            },
            {
                test: /\.s[ac]ss$/i,
                use: [
                    'style-loader',
                    'css-loader',
                    'sass-loader',
                ]
            },
            {
                test: /\.css$/i,
                use: [
                    'style-loader',
                    'css-loader',
                ]
            },
            {
                test: /\.(jpg|png)$/i,
                use: [
                    'file-loader',
                ]
            },
            {
                test: /\.glsl$/i,
                use: {
                    loader: 'webpack-glsl-minify',
                    options: {
                        preserveUniforms: true,
                    }
                }
            }
        ]
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: path.resolve(__dirname, "./index.html")
        }),
    ],
};