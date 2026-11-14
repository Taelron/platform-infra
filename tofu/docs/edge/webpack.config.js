// One bundle per Lambda@Edge function, written to dist/<function>.js.
// OpenTofu zips each bundle with its configuration.json (tofu/docs/edge.tf).
const path = require("path");
const TerserPlugin = require("terser-webpack-plugin");

const functions = [
  "check-auth",
  "parse-auth",
  "refresh-auth",
  "sign-out",
  "http-headers",
];

module.exports = {
  mode: "production",
  target: "node",
  node: { __dirname: false },
  entry: Object.fromEntries(
    functions.map((name) => [name, path.resolve(__dirname, "src", name, "index.ts")])
  ),
  output: {
    filename: "[name].js",
    libraryTarget: "commonjs",
    path: path.resolve(__dirname, "dist"),
    clean: true,
  },
  resolve: { extensions: [".ts", ".js"] },
  module: {
    rules: [
      { test: /\.ts$/, loader: "ts-loader", exclude: /node_modules/ },
      { test: /\.html$/i, loader: "html-loader", options: { minimize: true } },
    ],
  },
  optimization: {
    minimizer: [new TerserPlugin({ extractComments: false })],
  },
  performance: {
    hints: "error",
    // Largest package Lambda@Edge accepts for a viewer request.
    maxAssetSize: 1048576,
    maxEntrypointSize: 1048576,
  },
};
