# SwiftyMLC

https://github.com/user-attachments/assets/3951d6bb-b3bd-4820-b889-09a13ddf601e

SwiftyMLC is an example of how to integrate MLC into a Swift project. See the [mlc Swift SDK documentation](https://llm.mlc.ai/docs/deploy/ios.html#ios-swift-sdk) for more information.

## Running the App

1. Clone the project
2. Recursively initialize the mlc submodule   
```
git submodule update --init --recursive
```
3. Point to an iOS device (a limitation of MLC is that it can only be run on device)
4. Run!

- Set scheme to `release` for improved performance (at the downside of reduced debug ability).
- The `Increased Memory Limit` capability has also been enabled.  

## Updating Models

Ensure you have the following dependencies installed:

- [MLC LLM Python Package](https://llm.mlc.ai/docs/install/mlc_llm.html)
- CMake >= 3.24,
- Git and Git-LFS,
- Rust and Cargo, which are required by Hugging Face’s tokenizer.

### Configuring

Add the new model to `mlc-package-config.json` taking a look at the existing models. 
Notice that `name`, `bytes` and `group` aren't part of the original `mlc-package-config.json' spec.
These are properties used for the `ModelsScreen`.
You can retrieve the `bytes` of a model using the [Chrome HF Model Size](https://chromewebstore.google.com/detail/hf-model-size/poidchnginjmdckhofocjlanbnnondgc) extension.

### Fetching 

Run the following in the project directory.
```
export MLC_LLM_SOURCE_DIR={path to this repository}/mlc-llm
mlc_llm package
./model-details.sh
```
Model details maps name and bytes (custom properties) to `mlc-app-config.json`

If you ever change the file system structure (i.e. rename `ABC` to `CBA`), you may need to execute the above with
```
export MLC_DOWNLOAD_CACHE_POLICY=REDO
```

Also if you get an error you could try deleting the `build` folder.
