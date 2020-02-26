# Grafana

```bash
$ $(aws ecr get-login --no-include-email --region eu-central-1)
$ docker tag ymcne2019/grafana-custom:0.0.1 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/grafana:0.0.1
$ docker push 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/grafana:0.0.1

```