#!/usr/bin/env bash

AGENT_VERSION="master"
NAME_AGENT="vmonitor-agent"
BASE_URL="http://172.23.0.2/"
URL_INSTALL_DOCKER=$BASE_URL"docker_"
URL_ENV=$BASE_URL"env"
ENV_BASE_PATH="/opt/agent/"
ENV_PATH=$ENV_BASE_PATH".env"

#--- Display the 'welcome' splash/user warning info..
echo ""
echo "############################################################"
echo "#  Welcome Installer $NAME_AGENT:$AGENT_VERSION  #"
echo "############################################################"

echo -e "\nChecking that minimal requirements are ok"

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

get_distribution
if ! test -f $ENV_PATH; then
  mkdir -p $ENV_BASE_PATH
  curl -o $ENV_PATH $URL_ENV
  echo $API_KEY >> $ENV_PATH
fi

# install docker
if [[ "$lsb_dist" = "linuxmint" || "$lsb_dist" = "ubuntu" || "$lsb_dist" = "centos" ]]; then
  if ! command_exists docker ; then
    echo "############################################################"
    echo "install docker"
    echo "############################################################"
    bash <(curl -L -Ss $URL_INSTALL_DOCKER"$lsb_dist".sh)
  else
    docker stop agent-forwarder
    docker stop agent-collector
    docker rm agent-collector
    docker rm agent-forwarder
  fi
fi

if command_exists docker ; then
# run container
  docker run -d -it \
  --restart always \
  --env-file $ENV_PATH \
  --name agent-forwarder \
  --log-opt max-size=10m \
  --log-opt max-file=5 \
  --net host \
  registry.vngcloud.vn/monitor/agent-forwarder:master

  docker run -d -it \
  --restart always \
  --env-file $ENV_PATH \
  --name agent-collector \
  -v /:/rootfs:ro \
  -v /run/:/run/:shared \
  -v /dev:/dev:rw \
  --net host \
  --log-opt max-size=10m \
  --log-opt max-file=5 \
  registry.vngcloud.vn/monitor/agent-collector:master
fi
