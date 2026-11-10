#!/usr/bin/env bash
set -Eeuo pipefail

CLUSTER_NAME="${KIND_CLUSTER_NAME:-dood-kind}"
DOCKER_NETWORK="${KIND_DOCKER_NETWORK:-dood-kind-net}"
mkdir -p /shared

if [ ! -S /var/run/docker.sock ]; then
  echo "Host Docker socket /var/run/docker.sock is missing. Mount it from the host in compose.yaml." >&2
  exit 1
fi

printf 'Waiting for the host Docker daemon'
for _ in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    printf '\nHost Docker daemon is ready.\n'
    break
  fi
  printf '.'
  sleep 2
done
docker info >/dev/null 2>&1 || { echo 'Timed out waiting for host Docker daemon.' >&2; exit 1; }

# Kind's custom Docker network setting is experimental. It allows the Kind
# node containers created through the host socket to join the Compose network,
# so the Python client can reach the API server directly on the control-plane IP.
export KIND_EXPERIMENTAL_DOCKER_NETWORK="$DOCKER_NETWORK"

if ! kind get clusters 2>/dev/null | grep -Fxq "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --config /kind-config.yaml --wait 180s
else
  echo "Kind cluster '$CLUSTER_NAME' already exists; reusing it."
fi

CONTROL_PLANE_CONTAINER="${CLUSTER_NAME}-control-plane"
CONTROL_PLANE_IP="$(docker inspect -f "{{(index .NetworkSettings.Networks \"${DOCKER_NETWORK}\").IPAddress}}" "$CONTROL_PLANE_CONTAINER")"
if [ -z "$CONTROL_PLANE_IP" ] || [ "$CONTROL_PLANE_IP" = "<no value>" ]; then
  echo "Could not find $CONTROL_PLANE_CONTAINER on Docker network $DOCKER_NETWORK." >&2
  echo "Check that KIND_EXPERIMENTAL_DOCKER_NETWORK matches the Compose network name." >&2
  exit 1
fi

kind export kubeconfig --name "$CLUSTER_NAME" --kubeconfig /shared/config
# The default exported kubeconfig points to a host-published port. The client
# uses the control-plane node's IP on the shared Compose network instead.
sed -i "s#server: https://.*#server: https://${CONTROL_PLANE_IP}:6443#" /shared/config
chmod 0644 /shared/config

echo "Kind cluster '$CLUSTER_NAME' is using the host Docker daemon."
echo "Kubernetes API endpoint for Compose clients: https://${CONTROL_PLANE_IP}:6443"

# Keep this management container running so Compose can report cluster health.
exec tail -f /dev/null
