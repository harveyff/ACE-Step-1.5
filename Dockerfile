# x86-64 with CUDA 12.8 (NVIDIA GPU) version for ACE-Step 1.5
# 适用于：NVIDIA GPU 服务器（RTX 3090, A100, 等）
# 对于 ARM64 架构，请使用 Dockerfile.arm64
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    CUDA_HOME=/usr/local/cuda

WORKDIR /app

# 安装系统依赖和 Python 3.11
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-venv python3.11-dev \
    build-essential git curl wget sox libsox-dev libsndfile1 ffmpeg \
    ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建 Python 3.11 的符号链接（如果需要）
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# 创建虚拟环境
RUN python3.11 -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# 安装 pip 和升级到最新版本
RUN pip install --upgrade pip setuptools wheel

# 从构建上下文复制项目文件（而不是 git clone）
# 这样可以包含本地修改，避免网络问题，加快构建速度
COPY . /app/

# 先安装 PyTorch（flash-attn 需要 torch 才能构建）
# Linux x86-64 使用 PyTorch 2.10.0（根据 pyproject.toml）
RUN pip install torch==2.10.0 torchvision torchaudio==2.10.0 \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com || \
    pip install torch==2.10.0 torchvision torchaudio==2.10.0 \
        --extra-index-url https://download.pytorch.org/whl/cu128

# 安装其他核心依赖（排除 torch 相关和 flash-attn，稍后单独安装）
# 注意：版本约束需要用引号括起来，避免 shell 解释重定向符号
RUN pip install "transformers>=4.51.0,<4.58.0" \
        diffusers \
        "gradio>=6.5.1" \
        "matplotlib>=3.7.5" \
        "scipy>=1.10.1" \
        "soundfile>=0.13.1" \
        "loguru>=0.7.3" \
        "einops>=0.8.1" \
        "accelerate>=1.12.0" \
        "fastapi>=0.110.0" \
        diskcache \
        "uvicorn[standard]>=0.27.0" \
        "numba>=0.63.1" \
        "vector-quantize-pytorch>=1.27.15" \
        "torchcodec>=0.9.1" \
        torchao \
        modelscope \
        "peft>=0.7.0" \
        "lightning>=2.0.0" \
        "tensorboard>=2.0.0" \
        "triton>=3.0.0" \
        xxhash \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com || \
    pip install "transformers>=4.51.0,<4.58.0" \
        diffusers \
        "gradio>=6.5.1" \
        "matplotlib>=3.7.5" \
        "scipy>=1.10.1" \
        "soundfile>=0.13.1" \
        "loguru>=0.7.3" \
        "einops>=0.8.1" \
        "accelerate>=1.12.0" \
        "fastapi>=0.110.0" \
        diskcache \
        "uvicorn[standard]>=0.27.0" \
        "numba>=0.63.1" \
        "vector-quantize-pytorch>=1.27.15" \
        "torchcodec>=0.9.1" \
        torchao \
        modelscope \
        "peft>=0.7.0" \
        "lightning>=2.0.0" \
        "tensorboard>=2.0.0" \
        "triton>=3.0.0" \
        xxhash \
        --extra-index-url https://download.pytorch.org/whl/cu128

# 最后安装 flash-attn（需要 torch 已安装）
RUN pip install flash-attn \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com || \
    pip install flash-attn \
        --extra-index-url https://download.pytorch.org/whl/cu128 || \
    echo "Warning: flash-attn installation failed, continuing without it"

# 安装本地 nano-vllm 包（如果需要）
RUN if [ -d "acestep/third_parts/nano-vllm" ]; then \
        pip install -e acestep/third_parts/nano-vllm || true; \
    fi

# 创建工作目录并赋权
RUN mkdir -p /app/checkpoints /app/outputs /app/logs && \
    chown -R 1001:1001 /app

EXPOSE 7860
VOLUME [ "/app/checkpoints", "/app/outputs", "/app/logs" ]

# 使用 ACE-Step 1.5 的新入口点
ENTRYPOINT ["python3", "acestep/acestep_v15_pipeline.py", "--server-name", "0.0.0.0", "--port", "7860"]

