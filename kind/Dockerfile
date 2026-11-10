FROM alpine:3.22

RUN apk add --no-cache bash ca-certificates curl docker-cli grep sed coreutils

ARG KIND_VERSION=v0.33.0
RUN set -eux; \
    case "$(uname -m)" in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}" -o /usr/local/bin/kind; \
    chmod +x /usr/local/bin/kind; \
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"; \
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"; \
    chmod +x /usr/local/bin/kubectl

COPY kind-config.yaml /kind-config.yaml
COPY start-kind.sh /usr/local/bin/start-kind.sh
RUN chmod +x /usr/local/bin/start-kind.sh

ENTRYPOINT ["/usr/local/bin/start-kind.sh"]
