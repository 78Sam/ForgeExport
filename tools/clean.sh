#!/bin/bash

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker network rm $(docker network ls --filter type=custom -q)