# Sample service

```bash
$ docker build -t sample-app:0.0.1 .
$ docker images
$ docker run bb929d3d1297
```

```
$(aws ecr get-login --no-include-email --region eu-central-1)
docker tag sample-app:0.0.2 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/sample-service:0.0.2
docker push 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/sample-service:0.0.2
```