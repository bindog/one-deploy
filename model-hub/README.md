Build a file server from: [gohttpserver](https://github.com/codeskyblue/gohttpserver/releases/tag/1.1.0)

Put all your model and code file here

```bash
docker run -it --rm -p 8799:8000 -v $PWD:/app/public --name gohttpserver codeskyblue/gohttpserver --upload
```
