FROM julia:1.0.2

WORKDIR /app

COPY train.jl Project.toml /app/

ENV JULIA_PROJECT=/app

RUN mkdir /data
COPY data/wutheringheights.txt /app

VOLUME /data

RUN julia -e 'using Pkg; pkg"activate ."; pkg"instantiate"'

CMD julia train.jl --model-output-dir /data wutheringheights.txt

