# Build inference docker images

- copy the `pkg` folder from https://github.com/bindog/cortex to here
- create `cached_whl` folder and put the large *.whl into it


```bash
docker build . -f images/xxxx/Dockerfile --build-arg "HTTP_PROXY=http://xxxx:xx" --build-arg "HTTPS_PROXY=http://xxxx:xx"
```
