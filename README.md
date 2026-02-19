# Build Commands

### First: ubuntu

```
docker build --target ubuntu-fat -t demo:ubuntu-fat .
```

### Second: alpine

```
docker build --target alpine-slim -t demo:alpine-slim .
```

# Run commands
```
docker run --rm -p 8000:8000 demo:ubuntu-fat
```

```
docker run --rm -p 8000:8000 demo:alpine-slim
```

# Compare

docker images 

