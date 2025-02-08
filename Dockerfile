FROM continuumio/miniconda3:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        git \
        unzip \
        python3 \
        sudo \
        file \
        python3-vcstools \
        libboost-dev \
        vim \
        cpio \
        binutils \
        cmake \
        patch \
        supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN conda install conda-lock

WORKDIR /chipyard
RUN git clone https://github.com/ucb-bar/chipyard.git .

COPY ./scripts/build_chipyard.sh ./scripts/utils.sh ./scripts/stage.sh ./
RUN chmod +x ./build_chipyard.sh ./utils.sh ./stage.sh

RUN bash ./stage.sh 1 ; sed 's/conda activate/source activate/g' -i ./env.sh
RUN bash ./stage.sh 2
RUN bash ./stage.sh 3
RUN bash ./stage.sh 5
RUN bash ./stage.sh 10

RUN git pull; scripts/init-submodules-no-riscv-tools.sh
RUN bash ./build_chipyard.sh

WORKDIR /
COPY ./benchmarks /chipyard/tests
COPY ./build_configs /chipyard/build_configs
COPY ./scripts/build_benchmarks.py /chipyard/scripts/
COPY ./scripts/add_benchmarks.py /chipyard/scripts/
COPY ./scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY requirements.txt /chipyard/
RUN /opt/conda/bin/pip install --no-cache-dir -r /chipyard/requirements.txt

RUN python /chipyard/scripts/build_benchmarks.py

WORKDIR /chipyard
COPY ./scripts/start.sh ./tasks.py ./
RUN chmod +x ./start.sh
RUN chmod +x /chipyard/scripts/add_benchmarks.py

ENV CONFIG=GENV256D128ShuttleConfig
ENV BENCHMARK_DIR=/chipyard/tests
ENV RESULTS_DIR=/results
ENV NUM_WORKERS=1

ENTRYPOINT ["/chipyard/start.sh"]
