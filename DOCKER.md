# ACE-Step 1.5 Docker 部署指南

本仓库提供了多个 Dockerfile 以支持不同的架构和部署场景。

## 📦 可用的 Dockerfile

| Dockerfile | 架构 | GPU 支持 | 适用场景 |
|-----------|------|----------|---------|
| `Dockerfile` | x86-64 | NVIDIA CUDA 12.8 | 生产环境，NVIDIA GPU 服务器 |
| `Dockerfile.jetson` | ARM64 | NVIDIA CUDA (Jetson) | ✅ **NVIDIA Jetson 设备（推荐）** |
| `Dockerfile.arm64-cuda` | ARM64 | NVIDIA CUDA | NVIDIA Jetson 或其他 ARM64 CUDA 设备 |
| `Dockerfile.arm64` | ARM64 Linux | CPU-only | Linux ARM64 设备（AWS Graviton, Raspberry Pi 5, 等） |
| `Dockerfile.arm64-mps` | ARM64 macOS | MPS (仅限 macOS) | ⚠️ 参考用，实际应在 macOS 原生运行 |
| `Dockfile.txt` | x86-64 | NVIDIA CUDA 12.8 | 与 Dockerfile 相同（兼容旧命名） |

**重要提示**：
- 🍎 **Apple Silicon 用户**：请直接在 macOS 上运行，不要使用 Docker（MPS 在容器中不可用）
- 🚀 **NVIDIA Jetson 用户**：使用 `Dockerfile.jetson`（支持 CUDA GPU 加速）
- 🐧 **Linux ARM64 用户**：使用 `Dockerfile.arm64`（CPU-only）

## 🚀 快速开始

### x86-64 + NVIDIA GPU（推荐）

```bash
# 构建镜像
docker build -t ace-step-1.5:latest .

# 运行容器（需要 NVIDIA GPU）
docker run -d \
  --name ace-step \
  --gpus all \
  -p 7860:7860 \
  -v $(pwd)/checkpoints:/app/checkpoints \
  -v $(pwd)/outputs:/app/outputs \
  ace-step-1.5:latest
```

### NVIDIA Jetson (ARM64 + CUDA) ✅

**推荐使用 `Dockerfile.jetson`，专为 Jetson 优化：**

```bash
# 构建 Jetson 镜像（根据你的 JetPack 版本调整）
docker build -f Dockerfile.jetson \
  --build-arg JETPACK_VERSION=r35.2.1 \
  -t ace-step-1.5:jetson .

# 运行容器（需要 GPU 支持）
docker run -d \
  --name ace-step-jetson \
  --runtime nvidia \
  --gpus all \
  -p 7860:7860 \
  -v $(pwd)/checkpoints:/app/checkpoints \
  -v $(pwd)/outputs:/app/outputs \
  ace-step-1.5:jetson
```

**前置要求**：
- 已安装 JetPack SDK
- 已安装 NVIDIA Container Toolkit
- Docker 已配置 GPU 支持

**支持的 Jetson 设备**：
- Jetson AGX Xavier
- Jetson AGX Orin
- Jetson Xavier NX
- Jetson Orin NX
- Jetson Nano（性能可能受限）

### ARM64 CPU-only（Linux ARM64，如 AWS Graviton）

```bash
# 构建 ARM64 镜像
docker build -f Dockerfile.arm64 -t ace-step-1.5:arm64 .

# 运行容器（CPU-only）
docker run -d \
  --name ace-step-arm64 \
  -p 7860:7860 \
  -v $(pwd)/checkpoints:/app/checkpoints \
  -v $(pwd)/outputs:/app/outputs \
  ace-step-1.5:arm64
```

### Apple Silicon (M1/M2/M3) - macOS 原生运行（推荐）

**⚠️ 不要在 Docker 中运行，直接在 macOS 上运行以使用 MPS GPU 加速：**

```bash
# 安装依赖
uv sync

# 运行（自动使用 MPS GPU）
uv run acestep

# 或使用 Python
python acestep/acestep_v15_pipeline.py
```

**为什么？** Docker Desktop for Mac 运行的是 Linux 容器，无法访问 macOS 的 Metal/MPS API。

## 📋 架构支持说明

### ✅ x86-64 (AMD64)

- **GPU**: NVIDIA CUDA 12.8
- **性能**: 最佳性能，支持 GPU 加速
- **推荐配置**: 
  - RTX 3090 (24GB VRAM)
  - A100 (40GB/80GB VRAM)
  - 或其他支持 CUDA 12.8 的 NVIDIA GPU

### ⚠️ ARM64 (aarch64)

#### Apple Silicon (M1/M2/M3) - macOS

- **GPU**: ✅ 支持 MPS (Metal Performance Shaders)
- **性能**: 良好（使用 GPU 加速）
- **重要**: **MPS 仅在 macOS 原生环境中可用**

**推荐方式（不使用 Docker）**:
```bash
# 直接在 macOS 上运行（推荐）
uv run acestep

# 或使用 Python
python acestep/acestep_v15_pipeline.py
```

**为什么不在 Docker 中使用 MPS**:
- Docker Desktop for Mac 运行的是 Linux 容器，不是 macOS 容器
- MPS 是 macOS 特有的 API，Linux 容器无法访问
- 在 Docker 中运行会回退到 CPU 模式

#### NVIDIA Jetson (ARM64 + CUDA) ✅

- **GPU**: ✅ 支持 NVIDIA CUDA（通过 JetPack SDK）
- **性能**: 良好（使用 GPU 加速）
- **适用设备**: Jetson AGX Xavier, Orin, Xavier NX, Orin NX, Nano

**推荐使用 `Dockerfile.jetson`**:
```bash
docker build -f Dockerfile.jetson --build-arg JETPACK_VERSION=r35.2.1 -t ace-step-1.5:jetson .
docker run --runtime nvidia --gpus all -p 7860:7860 ace-step-1.5:jetson
```

**注意事项**:
- ✅ 支持 CUDA GPU 加速
- ✅ 支持 PyTorch CUDA 后端
- ⚠️ 需要匹配的 JetPack 版本和 CUDA 版本
- ⚠️ 某些依赖（如 flash-attn）可能需要特殊编译
- ⚠️ nano-vllm 可能需要特殊配置

#### Linux ARM64 (AWS Graviton, Raspberry Pi 5, 等)

- **GPU**: ❌ 不支持（CPU-only）
- **性能**: 较慢，仅适合测试或轻量级使用

**限制**:
- ❌ 不支持 CUDA（ARM64 Linux 上 CUDA 支持有限，主要限于 NVIDIA Jetson）
- ❌ 不支持 MPS（MPS 仅限 macOS）
- ❌ 不支持 nano-vllm 加速
- ❌ 不支持 torchcodec（某些功能可能不可用）
- ⚠️ 推理速度较慢（纯 CPU）
- ⚠️ 建议禁用 LLM（`--init_llm false`）

## 🔧 构建多架构镜像（高级）

使用 Docker Buildx 构建多架构镜像：

```bash
# 创建 buildx builder
docker buildx create --name multiarch --use

# 构建并推送多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile \
  -t your-registry/ace-step-1.5:latest \
  --push .
```

**注意**: 多架构构建需要：
- Docker Buildx
- 支持多架构的基础镜像
- 可能需要交叉编译某些依赖

## 📝 环境变量配置

可以通过环境变量或 `.env` 文件配置 ACE-Step：

```bash
# 禁用 LLM（节省内存）
-e ACESTEP_INIT_LLM=false

# 指定模型下载源
-e ACESTEP_DOWNLOAD_SOURCE=modelscope

# 指定 DiT 模型
-e ACESTEP_CONFIG_PATH=acestep-v15-turbo

# 指定 LM 模型
-e ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-0.6B
```

## 🐳 Docker Compose 示例

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  ace-step:
    build:
      context: .
      dockerfile: Dockerfile
    image: ace-step-1.5:latest
    ports:
      - "7860:7860"
    volumes:
      - ./checkpoints:/app/checkpoints
      - ./outputs:/app/outputs
      - ./logs:/app/logs
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    environment:
      - ACESTEP_INIT_LLM=auto
      - ACESTEP_DOWNLOAD_SOURCE=auto
    restart: unless-stopped
```

运行：

```bash
docker-compose up -d
```

## 🔍 故障排除

### ARM64 构建失败

如果 ARM64 构建失败，可能原因：
1. 某些依赖不支持 ARM64
2. PyTorch ARM64 版本问题
3. 编译工具链问题

**解决方案**: 使用 x86-64 服务器或云平台部署

### GPU 不可用

检查 NVIDIA Docker 运行时：

```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi
```

### 模型下载失败

设置下载源：

```bash
docker run ... -e ACESTEP_DOWNLOAD_SOURCE=modelscope ...
```

## 📚 更多信息

- [ACE-Step 1.5 官方文档](https://github.com/ACE-Step/ACE-Step-1.5)
- [GPU 兼容性指南](./docs/en/GPU_COMPATIBILITY.md)
- [API 文档](./docs/en/API.md)

