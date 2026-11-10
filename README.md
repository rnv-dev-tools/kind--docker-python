# Alpine DooD Kind + Python client lab (Docker Compose)

This lab uses **Docker-outside-of-Docker (DooD)**. The `dood-kind` management container is Alpine Linux and talks to the **host Docker daemon** through `/var/run/docker.sock`. It does not run a nested Docker daemon and does not use Docker-in-Docker.

The Kind Kubernetes nodes are separate containers created by the host Docker daemon. The Python client is another separate Alpine-based container with Bash, Python, the Kubernetes Python SDK, `kubectl`, Git, and `uv`.

## Architecture

- `dood-kind`: Alpine + Docker CLI + Kind CLI + kubectl. Uses the host Docker socket to create/delete Kind node containers.
- `python-client`: Alpine + Python 3.12 + Kubernetes Python SDK + kubectl + Git + uv. This is the interactive terminal where you run commands.
- `dood-kind-net`: shared Docker bridge network. Kind node containers are attached to this network using Kind's **experimental** `KIND_EXPERIMENTAL_DOCKER_NETWORK` setting. The Python client reaches the API server directly through the control-plane node's network IP.
- `kubeconfig-data`: named volume that shares kubeconfig from the manager to the Python client. The client mounts it read-only.
- `workspace/`: host directory mounted into the Python client at `/workspace` for your scripts and Git repositories.

> **Security warning:** Access to `/var/run/docker.sock` effectively grants root-equivalent control over the host Docker daemon. Only use this on a trusted development machine. Kind's custom Docker network setting is experimental and may change in future Kind releases.

## Requirements

- Linux with Docker Engine and the Docker Compose plugin
- Host Docker daemon running and `/var/run/docker.sock` accessible
- Internet access for image builds and Kubernetes node image pulls

Host-installed Kind, kubectl, Python, Git, and uv are not required. Docker itself must be installed on the host because DooD deliberately uses its daemon.

## Start the lab

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f dood-kind
```

Wait until `dood-kind` is `healthy` and `python-client` is running. Use `Ctrl+C` to stop following logs; the services continue running.

## Enter the Python client

```bash
docker compose exec python-client bash
```

Inside the Python container:

```bash
kubectl get nodes
kubectl get pods -A
kubectl run demo-nginx --image=nginx:alpine
kubectl get pods -o wide
kubectl describe pod demo-nginx
kubectl delete pod demo-nginx

git --version
uv --version
python --version
```

`KUBECONFIG=/shared/config` and context `kind-dood-kind` are configured for you.

## Use the Python Kubernetes SDK app

From the host, run:

```bash
docker compose exec python-client python /app/app.py create demo-nginx --image nginx:alpine
docker compose exec python-client python /app/app.py list
docker compose exec python-client python /app/app.py delete demo-nginx
```

Or run those same `python /app/app.py ...` commands from inside the interactive shell.

## Git and uv workspace

```bash
cd /workspace
git clone https://github.com/your-org/your-repo.git
cd your-repo
uv venv
uv pip install -r requirements.txt
```

Files in `/workspace` persist in the project directory on the host. Python environments created there persist too.

## Stop or reset

Stop the services while preserving the Kind node containers and shared network:

```bash
docker compose stop
```

Start them again later with `docker compose up -d`.

To delete the Kind cluster and remove all lab services and volumes:

```bash
docker compose exec dood-kind kind delete cluster --name dood-kind
docker compose down -v
```

If the manager service is already stopped, start it first so the `kind` CLI can delete the cluster. As a last resort, remove the node containers through the host Docker daemon:

```bash
docker rm -f dood-kind-control-plane dood-kind-worker
docker compose down -v
```
