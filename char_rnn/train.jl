using ArgParse
using Base.Iterators: partition
using Dates
using Flux
using Flux: onehot, chunk, batchseq, throttle, crossentropy
using JLD2
using StatsBase: wsample

ap = ArgParseSettings()
@add_arg_table ap begin
    "--model-name"
    help = "model name in serialized model file (written after each epoch)"
    arg_type = String
    default = "model"

    "--load-model-file"
    required = false
    default = nothing

    "--epochs"
    help = "how many times to iterate over the training data"
    arg_type = Int
    default = 10

    "--hidden-layer-size"
    help = "dimensionality of the hidden layer of the LSTM"
    arg_type = Int
    default = 128

    "--batches"
    help = "how many minibatches to use"
    arg_type = Int
    default = 50

    "--sequence-length"
    help = "length of each text sequence"
    arg_type = Int
    default = 50

    "training-files"
    help = "text files to use as training data"
    nargs = '+'
    required = true
end
args = parse_args(ap)

const stopchar = '~'

gettext(file::String) = read(file, String)
gettext(files::Vector) = string(gettext.(files))

println("reading input...")
text = gettext(args["training-files"])

println("preparing data...")
alphabet = [unique(text)..., stopchar]

text = [onehot(ch, alphabet) for ch in text]
stop = onehot(stopchar, alphabet)

NV = length(alphabet)
NH = args["hidden-layer-size"]

function text2batches(text)
    batchseqs = batchseq(chunk(text, args["batches"]), stop)
    return collect(partition(batchseqs, args["sequence-length"]))
end

Xs = text2batches(text)
Ys = text2batches(text[2:end])

if args["load-model-file"] == nothing
    println("initializing model...")
    model = Chain(
        LSTM(NV, NH),
        LSTM(NH, NH),
        Dense(NH, NV),
        softmax)
else
    modelfile = args["load-model-file"]
    println("loading model from file $modelfile...")
    # BSON.@load modelfile model
    JLD2.@load modelfile alphabet model
end

function loss(xs, ys)
    loss_ = sum(crossentropy.(model.(xs), ys))
    Flux.truncate!(model)
    return loss_
end

opt = ADAM(params(model), 0.01)

tx, ty = Xs[5], Ys[5]

function training_cb()
    @show loss(tx, ty)
    println(sample(model, alphabet, 100))
    println()
end

function sample(model, alphabet, len; temp = 1)
    Flux.reset!(model)
    buf = IOBuffer()
    c = 'T'
    for i = 1:len
        write(buf, c)
        c = wsample(alphabet, model(onehot(c, alphabet)).data)
    end
    return String(take!(buf))
end

function model_name()
    name = args["model-name"]
    return "$(name)_$(Dates.now()).jld2"
end
    

println("training language model!")
Flux.@epochs args["epochs"] begin
    Flux.train!(loss, zip(Xs, Ys), opt, cb = throttle(training_cb, 30))
    filename = model_name()
    println("saving model to $filename...")
    JLD2.@save filename alphabet model
end
