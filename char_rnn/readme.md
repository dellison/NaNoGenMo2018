# Character-level language models

## Training a language model in a docker image

```
docker build . -f char_rnn-trainer.Dockerfile -t trainerimage
docker run trainerimage
```

## Training a language model locally (without docker)

1. Install [Julia](https://julialang.org/)
2. Install dependencies

To install the dependencies globally:

```shell
$ julia -e 'using Pkg; pkg"add Flux JLD2 StatsBase"
```
This invokes Julia's built-in package manager, [Pkg](https://docs.julialang.org/en/v1/stdlib/Pkg/), and installs the julia packages that are used for the language model. This is similar to using the `pip` tool in python and installing python packages using `pip install`.

Now that you have julia and the dependencies installed, you're ready to train a model!

```shell
$ julia train.jl --model-name mymodel corpus1.txt corpus2.txt
```
