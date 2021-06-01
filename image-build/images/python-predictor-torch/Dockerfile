#############################################################
# First Stage
FROM nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04 as builder

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \ 
    rm /etc/apt/sources.list.d/cuda.list && \
    rm /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update -qq && apt-get install -y -q \
        build-essential \
        pkg-config \
        software-properties-common \
        curl \
        git \
        unzip \
        zlib1g-dev \
        locales \
        nginx=1.18.* \
    && apt-get clean -qq && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8

ENV PATH=/opt/conda/bin:$PATH
ENV PYTHONVERSION=3.6.9

# conda needs an untainted base environment to function properly
# that's why a new separate conda environment is created
RUN curl "https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh" --output ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm -rf ~/.cache ~/miniconda.sh

# split the conda installations because the dev boxes have limited memory
RUN /opt/conda/bin/conda create -n env -c conda-forge python=$PYTHONVERSION pip=19.* && \
    /opt/conda/bin/conda clean -a && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" > ~/.env && \
    echo "conda activate env" >> ~/.env && \
    echo "source ~/.env" >> ~/.bashrc

ENV BASH_ENV=~/.env
SHELL ["/bin/bash", "-c"]

RUN mkdir ~/.pip && \
    printf '%s\n%s\n%s\n' '[global]' 'trusted-host = mirrors.aliyun.com' \
    'index-url = https://mirrors.aliyun.com/pypi/simple' >> ~/.pip/pip.conf

COPY serve/serve.requirements.txt /src/cortex/serve/serve.requirements.txt
COPY serve/cortex_internal.requirements.txt /src/cortex/serve/cortex_internal.requirements.txt
RUN pip install --no-cache-dir \
    -r /src/cortex/serve/serve.requirements.txt \
    -r /src/cortex/serve/cortex_internal.requirements.txt
RUN pip install --no-cache-dir torch==1.8.1+cu111 -f https://download.pytorch.org/whl/torch_stable.html

COPY serve/init/install-core-dependencies.sh /usr/local/cortex/install-core-dependencies.sh
RUN chmod +x /usr/local/cortex/install-core-dependencies.sh

COPY serve/ /src/cortex/serve
#############################################################
# Second Stage
FROM nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04

RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \ 
    rm /etc/apt/sources.list.d/cuda.list && \
    rm /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update -qq && apt-get install -y -q \
        curl \
        locales \
        nginx=1.18.* \
    && apt-get clean -qq && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /root /root
COPY --from=builder /src /src
COPY --from=builder /usr/local/cortex/install-core-dependencies.sh /usr/local/cortex/install-core-dependencies.sh

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.en LC_ALL=en_US.UTF-8
ENV PATH=/opt/conda/bin:$PATH
ENV BASH_ENV=~/.env
SHELL ["/bin/bash", "-c"]

ENTRYPOINT ["/bin/bash", "/src/cortex/serve/init/bootloader_k8s.sh"]
