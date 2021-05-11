# The Watness III

This is the third (and final!) installment of the Watness trilogy from PlaidCTF. This puzzle is a static webpage that loads a WebGL game that implements a simple version of the witness. The catch is that the whole game is a single shader, with the JS harness serving only to manage inputs and outputs.

## Running locally

To run locally, first install all the dependencies with `yarn install`.

Then, to start a development build, run `yarn watch` and go to `http://localhost:5500`. Alternatively, you can start a production build with `yarn build`. All the output will be in `dist/`.

## Windows Issues

Note that if you're using Windows, you'll need to disable Angle in your browser for this to work. That can be found in `about:flags` for Chrome, or the settings for Firefox.