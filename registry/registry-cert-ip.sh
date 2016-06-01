sudo apt-get update
sudo apt-get -y install jq

# Creae a certificate
cp /usr/lib/ssl/openssl.cnf ./openssl.cnf
sed -i "/\[ v3_ca \]/a subjectAltName = IP:192.168.0.1" ./openssl.cnf
openssl req -config ./openssl.cnf -newkey rsa:2048 -nodes -keyout domain.key -x509 -days 365 -out domain.crt -subj "/C=US/ST=WA/L=Mill Creek/O=Flak.IO/CN=192.168.0.1"

# Get the list of agents in the cluster
declare -a MESOS_AGENTS=$(curl -sS master.mesos:5050/slaves | jq '.slaves[] | .hostname' | tr -d '"');

# Copy certificate to all agent nodes
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no "sudo mkdir --parent /etc/privateregistry/certs/"; done
for i in $MESOS_AGENTS; do scp -o StrictHostKeyChecking=no ./domain.* "$i":~/; done
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no "sudo mv ./domain.* /etc/privateregistry/certs/"; done

# Link certificate to docker and restart docker
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no "sudo mkdir --parent /etc/docker/certs.d/192.168.0.1"; done
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no "sudo ln -s /etc/privateregistry/certs/domain.crt /etc/docker/certs.d/192.168.0.1/ca.crt"; done
for i in $MESOS_AGENTS; do ssh "$i" -oStrictHostKeyChecking=no "sudo systemctl restart docker"; done

# Deploy the registry
STORAGE_ACCOUNT_NAME=$(grep com\.netflix\.exhibitor\.azure\.account-name /opt/mesosphere/etc/exhibitor.properties | cut -d = -f 2-)
STORAGE_ACCOUNT_KEY=$(grep com\.netflix\.exhibitor\.azure\.account-key /opt/mesosphere/etc/exhibitor.properties | cut -d = -f 2-)
read -r -d '' MARATHON_REGISTRY << EOM
{
  "id": "/registry",
  "cmd": null,
  "cpus": 0.5,
  "mem": 128,
  "disk": 0,
  "instances": 1,
  "container": {
    "type": "DOCKER",
    "volumes": [
      {
        "containerPath": "/certs/",
        "hostPath": "/etc/privateregistry/certs/",
        "mode": "RO"
      }
    ],
    "docker": {
      "image": "registry:2",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 5000,
          "hostPort": 0,
          "servicePort": 10000,
          "protocol": "tcp",
          "labels": {
            "VIP_0": "192.168.0.1:443"
          }
        }
      ],
      "privileged": false,
      "parameters": [],
      "forcePullImage": false
    }
  },
  "env": {
    "REGISTRY_HTTP_TLS_CERTIFICATE": "/certs/domain.crt",
    "REGISTRY_HTTP_TLS_KEY": "/certs/domain.key",
    "REGISTRY_STORAGE": "azure",
    "REGISTRY_STORAGE_AZURE_ACCOUNTNAME": "$STORAGE_ACCOUNT_NAME",
    "REGISTRY_STORAGE_AZURE_ACCOUNTKEY": "$STORAGE_ACCOUNT_KEY",
    "REGISTRY_STORAGE_AZURE_CONTAINER": "registry"
  },
  "portDefinitions": [
    {
      "port": 10000,
      "protocol": "tcp",
      "labels": {}
    }
  ]
}
EOM

curl -Ss -XPOST master.mesos/marathon/v2/apps -d "$MARATHON_REGISTRY" -H "Content-Type:application/json"
