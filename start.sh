#!/bin/bash

docker-compose -f docker-compose.yml up -d

sleep 60

#docker cp ./cassandra/cass.sql tronex-docker_cassandra-1_1:./cass.sql

docker exec tronexdocker_cassandra-1_1 ./cass.sh
echo "SETUP DB TABLES ON CASSANDRA CLUSTER"

docker exec elasticsearch bash -c 'cd ./mappings/; ./addMappings.sh'

# Service application layer config #
elasticsearch_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' elasticsearch)
cass_1_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' tronexdocker_cassandra-1_1)
tron_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' tronexdocker_tron-node_1)

sed -i -e "s/elasticsearch_ip=\"*.*.*.*\"/elasticsearch_ip=\"$elasticsearch_ip\"/g" ./service-layer/update-ips.sh
sed -i -e "s/cass_1_ip=\"*.*.*.*\"/cass_1_ip=\"$cass_1_ip\"/g" ./service-layer/update-ips.sh
sed -i -e "s/tron_ip=\"*.*.*.*\"/tron_ip=\"$tron_ip\"/g" ./service-layer/update-ips.sh

docker cp service-layer/update-ips.sh tronexdocker_service-layer_1:/block-chain-explorer/update-ips.sh
docker exec tronexdocker_service-layer_1 /bin/sh -c "./update-ips.sh"

echo "STARTING SERVICE LAYER"
docker exec tronexdocker_service-layer_1 node index.js
