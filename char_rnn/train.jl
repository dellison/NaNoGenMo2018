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

    "--model-output-dir"
    help = "directory for serialized models"
    arg_type = String
    default = "."

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

# remove carriage returns and normalize whitespace
function normalize_whitespace(text)
    text = replace(text, "\r" => "")
    text = replace(text, r"([^\s])\n([^\s])" => s"\1 \2")
    text = replace(text, r"\s+" => " ")
    return text
end

text = normalize_whitespace(text)

alphabet = [unique(text)..., stopchar]

text = [onehot(ch, alphabet) for ch in text]
stop = onehot(stopchar, alphabet)

NV = length(alphabet)
NH = args["hidden-layer-size"]

println("size of dataset: $(length(text)) characters")
println("size of alphabet: $(length(alphabet)) unique characters\n")

function text2batches(text)
    batchseqs = batchseq(chunk(text, args["batches"]), stop)
    return collect(partition(batchseqs, args["sequence-length"]))
end

Xs = text2batches(text)
Ys = text2batches(text[2:end])

println("initializing model...")
model = Chain(
    LSTM(NV, NH),
    LSTM(NH, NH),
    Dense(NH, NV),
    softmax)
nparams = sum(map(length, params(model)))
println("model has $nparams trainable parameters\n")

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
        write(buf, string(c))
        c = wsample(alphabet, model(onehot(c, alphabet)).data)
    end
    Flux.reset!(model)
    Flux.truncate!(model)
    return String(take!(buf))
end

function model_name()
    name = args["model-name"]
    return joinpath(args["model-output-dir"], "$(name)_$(Dates.now()).jld2")
end
    
println("training language model!")
Flux.@epochs args["epochs"] begin
    Flux.train!(loss, zip(Xs, Ys), opt, cb = throttle(training_cb, 30))
    filename = model_name()
    println("saving model to $filename...")
    JLD2.@save filename alphabet model
end
