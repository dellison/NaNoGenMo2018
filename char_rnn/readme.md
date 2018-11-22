# Character-level language models

## Training character-level language models

### Training a language model in a docker image

Create a directory to share between the host and the container for serialized models.

```shell
$ mkdir ~/models
```

Build and run the docker container:

```
docker build . -f char_rnn-trainer.Dockerfile -t trainerlol
docker run -v ~/models:/data trainerlol
```

Model files will be written to the `~/models` directory.

(Note that you can name your image something besides "trainerlol")

### Training a language model locally (without docker)

1. Install [Julia](https://julialang.org/)
2. Install dependencies

To install the dependencies globally:

```shell
$ julia -e 'using Pkg; pkg"add ArgParse Flux JLD2 StatsBase"
```
This invokes Julia's built-in package manager, [Pkg](https://docs.julialang.org/en/v1/stdlib/Pkg/), and installs the julia packages that are used for the language model. This is similar to using the `pip` tool in python and installing python packages using `pip install`.

Now that you have julia and the dependencies installed, you're ready to train a model!

```shell
$ julia train.jl --model-name mymodel corpus1.txt corpus2.txt
```

## Generating text from a character-level language model

### Generating text using a docker container

Build and run the docker container:

```shell
$ docker build -f char_rnn-generator.Dockerfile -t generatorlol .
$ docker run -t generatorlol
```

### Generating text locally from a language model (without docker)

1. Install Julia and dependencies (see above)
2. Run `generate.jl`

```shell
$ julia generate.jl --model modelfile ...
```
