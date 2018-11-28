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

    "--input-file"
    help = ""
    arg_type = String

    "--output-file"
    help = ""
    arg_type = String
end
args = parse_args(ap)

JLD2.@load args["model"] alphabet model

function generate(seed, len)
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
    while ! (c in ('.', '?', '!'))
        c = wsample(alphabet, model(Flux.onehot(c, alphabet)).data)
        write(buf, c)
    end
    return String(take!(buf))
end


function get_paragraphs(filename)
    open(filename) do f
        text = read(f, String)
        text = replace(text, '\r' => "")
        return [replace(para, r"\n+" => " ") for para in strip.(split(text, r"\n\n+"))]
    end
end

# TODO: make this not suck so much
function split_sentences(paragraph)
    i = 1
    sentences = []
    j = findnext(r"[!\.\?]", paragraph, 1)
    if j == nothing
        return [paragraph]
    end
    push!(sentences, strip(paragraph[i:j[end]]))
    i = j[end] + 1
    while i <= length(paragraph) && j[end] <= length(paragraph)
        i = j[end] + 1
        j = findnext(r"[!\.\?]", paragraph, i)
        if i == nothing || j == nothing
            push!(sentences, strip(paragraph[i:end]))
            break
        else
            push!(sentences, strip(paragraph[i:j[end]]))
        end
    end
    return sentences
end

function filter_paragraph(paragraph)
    sentences = split_sentences(paragraph)
    return length(sentences) > 2
end

function maybe_rewrite_paragraph(paragraph)
    if filter_paragraph(paragraph)
        sentences = split_sentences(paragraph)
        chars_to_generate = length(paragraph)
        generated_text = generate(sentences[1], chars_to_generate)
        new_paragraph = replace(generated_text, r"[\r\n]+" =>" ")
        return new_paragraph
    else
        return paragraph
    end
end

paragraphs = get_paragraphs(args["input-file"])

open(args["output-file"], write=true) do f
    for paragraph in paragraphs
        text = maybe_rewrite_paragraph(paragraph)
        text = replace(text, r"(\\[nr])+" => " ")
        text = replace(text, "\\" => "")
        write(f, text)
        write(f, "\n\n")
    end
end
