using ArgParse
using Flux
using JLD2
using StatsBase

ap = ArgParseSettings()
@add_arg_table ap begin
    "--model"
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

    "--output-file"
    help = ""
    default = nothing
end
args = parse_args(ap)

JLD2.@load args["model"] alphabet model

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

generated_text = generate(model, args["seed"], alphabet, args["length"])

if args["output-file"] == nothing
    println(generated_text)
else
    open(args["output-file"], write=true) do f
        write(generated_text)
    end
end
