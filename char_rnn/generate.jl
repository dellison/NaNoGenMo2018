using ArgParse
using Flux
using JLD2
using StatsBase

ap = ArgParseSettings()
@add_arg_table ap begin
    "--model-name"
    help = "model to load"
    arg_type = String
    default = "model"

    "--length"
    help = "length of generated text"
    arg_type = Int
    default = 100

    "--seed"
    help = "initial text"
    arg_type = String
    default = ""
end
args = parse_args(ap)

JLD2.@load args["model-name"] alphabet model

function generate(model, seed, alphabet, len)
    seed = args["seed"]
    Flux.reset!(model)
    buf = IOBuffer()
    if length(seed) == 0
        seed = string(rand(alphabet))
    end
    for c in seed[1:end-1]
        write(buf, c)
        model(Flux.onehot(c, alphabet))
    end
    c = seed[end]
    for i = 1:len
        write(buf, c)
        c = wsample(alphabet, model(Flux.onehot(c, alphabet)).data)
    end
    return String(take!(buf))
end

println(generate(model, args["seed"], alphabet, args["length"]))
