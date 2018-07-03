This image is hosted on docker hub :
https://hub.docker.com/r/ignitioncoin/run_wallet/

To update it, edit the Dockerfile and run
```
docker login
docker build . -t ignitioncoin/run_wallet
docker push
```