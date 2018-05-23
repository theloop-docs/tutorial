#!/usr/bin/env bash

##############################################
#           환경변수등록
##############################################

export TAG=latest
export CONF=$(pwd)/conf
export LOGS=$(pwd)/logs
export FLUENTD=$(pwd)/fluentd
export STORAGE_RS=$(pwd)/storageRS
export STORAGE_PEER_0=$(pwd)/storage0
export STORAGE_PEER_1=$(pwd)/storage1

##############################################
#       로그 및 데이터 디렉토리 생성
##############################################
if [ ! -d ${LOGS} ]
    then    mkdir -p ${LOGS}
fi

if [ ! -d ${STORAGE_RS} ]
    then    mkdir -p ${STORAGE_RS}
fi

if [ ! -d ${STORAGE_PEER_0} ]
    then    mkdir -p ${STORAGE_PEER_0}
fi

if [ ! -d ${STORAGE_PEER_1} ]
    then    mkdir -p ${STORAGE_PEER_1}
fi

##############################################
#           로그서버실행
##############################################
docker run -d \
--name loop-logger \
--publish 24224:24224/tcp \
--volume ${FLUENTD}:/fluentd \
--volume ${LOGS}:/logs \
loopchain/loopchain-fluentd:${TAG}

##############################################
# Radio Station 실행
##############################################
docker run -d --name radio_station \
-v ${CONF}:/conf \
-v ${STORAGE_RS}:/storage \
-p 7102:7102 \
-p 9002:9002 \
--log-driver fluentd --log-opt fluentd-address=localhost:24224 \
loopchain/looprs:${TAG} \
python3 radiostation.py -o /conf/rs_conf.json

##############################################
#           Peer0 실행
##############################################
docker run -d --name peer0 \
-v $(pwd)/conf:/conf \
-v $(pwd)/storage0:/storage \
--link radio_station:radio_station \
--log-driver fluentd --log-opt fluentd-address=localhost:24224 \
-p 7100:7100 -p 9000:9000 \
loopchain/looppeer:${TAG} \
python3 peer.py -o /conf/peer_conf0.json -p 7100 -r radio_station:7102

##############################################
#           Peer1 실행
##############################################
docker run -d --name peer1 \
-v $(pwd)/conf:/conf \
-v $(pwd)/storage1:/storage \
--link radio_station:radio_station \
--log-driver fluentd --log-opt fluentd-address=localhost:24224 \
-p 7200:7200 -p 9100:9100 \
loopchain/looppeer:${TAG} \
python3 peer.py -o /conf/peer_conf1.json -p 7200 -r radio_station:7102

