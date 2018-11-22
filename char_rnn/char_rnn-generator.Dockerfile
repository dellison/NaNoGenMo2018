FROM julia:1.0.2

WORKDIR /app

ENV JULIA_PROJECT=/app

COPY generate.jl Project.toml /app/

RUN mkdir /text

RUN julia -e 'using Pkg; pkg"activate ."; pkg"instantiate"; pkg"precompile"'

## edit these two lines (change model file, command line args)
COPY wutheringheights.model.jld2 /app
CMD julia generate.jl --model wutheringheights.model.jld2 --length 1000 --seed "It was a dark and stormy night. "
