To run the ignition wallet client:

- Install docker https://docs.docker.com/install/
- Run :
`docker run -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v <absolute-path-to-ignition-sources>:/project ignitioncoin/run_wallet`