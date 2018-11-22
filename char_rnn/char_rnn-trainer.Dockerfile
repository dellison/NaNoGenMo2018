FROM julia:1.0.2

WORKDIR /app

COPY train.jl Project.toml /app/

ENV JULIA_PROJECT=/app

RUN mkdir /data

RUN julia -e 'using Pkg; pkg"activate ."; pkg"instantiate"; pkg"precompile"'

## edit these two lines (change training files, command line args)
COPY wutheringheights.txt /app
CMD julia train.jl --model-output-dir /data wutheringheights.txt

