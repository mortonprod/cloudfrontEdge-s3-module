const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');

module.exports = {
  mode: 'development',
  entry: {
    app: './src/index.js'
  },
  plugins: [
    new CleanWebpackPlugin(['dist']),
    new HtmlWebpackPlugin({
      title: 'Development',
      template: 'src/index.html'
    }),
  ],
  output: {
    filename: '[name].bundle.js',
    // path: path.resolve(__dirname)
    path: path.resolve(__dirname, 'dist')
  }
};