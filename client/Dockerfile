FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    KUBECONFIG=/shared/config \
    PATH="/root/.local/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl git grep sed \
    && rm -rf /var/lib/apt/lists/*

# Install uv using its official installer. Install kubectl for interactive CLI use.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && set -eux; \
       case "$(uname -m)" in \
         x86_64) ARCH=amd64 ;; \
         aarch64) ARCH=arm64 ;; \
         *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
       esac; \
       KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"; \
       curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"; \
       chmod +x /usr/local/bin/kubectl

#WORKDIR /app
#WORKDIR /workspace
#COPY requirements.txt /app/requirements.txt
#RUN uv pip install --system -r /app/requirements.txt
#COPY app.py /app/app.py

#WORKDIR /workspace
#CMD ["bash", "-lc", "sleep infinity"]
