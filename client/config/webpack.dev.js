const path = require('path');

const { merge } = require('webpack-merge');
const common = require('./webpack.common.js');
const HtmlWebpackPlugin = require('html-webpack-plugin');


const dev = {
    mode: 'development',
    devServer: {
        inline: true,
        hot: true,
        stats: "errors-only",
        contentBase: path.join(__dirname, "../src/assets"),
        publicPath: "/",
        historyApiFallback: true,
        // feel free to delete this section if you don't need anything like this
        before(app) {
            // on port 3000
            app.get("/test", function (req, res) {
                res.json({ result: "OK" });
            });
        }
    },
    plugins: [
        new HtmlWebpackPlugin({
            inject: 'body',
            filename: 'index.html',
            template: require('html-webpack-template'),
            appMountId: 'main',
            mobile: true,
            lang: 'en-US',
            links: [],
            xhtml: true,
            hash: false,
            chunks: ['main'],
            favicon: '../client/src/assets/images/favicon.ico'
        }),
    ]
};

module.exports = env => {
    const withDebug = !env.nodebug;
    return merge(common(withDebug), dev);
}
