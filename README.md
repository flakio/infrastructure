#Flak.io Infrastructure

## Configuration
Managing configuration

## Management
After provisioning a new Mesos cluster using the ACS mesos orchestrator option, we can connect with ssh client with port forwarding setup and agent forwarding.

`ssh {user}@{dnslabel}mgmt.westus.cloudapp.azure.com -A -p 2200 -L 8080:localhost:8080 -L 5050:master.mesos:5050 -L 4400:localhost:4400`

The `-L` options forward local ports to endpoints and ports on the target system. Mesos master is not listening on local host so we need to use the master IP address instead.  The `-A` option enables agent forwarding and allows us to connect to other systems in the cluster.

## Marathon-lb
A marathon-lb instance needs to be deployed to handle incoming traffic.  We will deploy two instances in the load balancer and rely on the fact that the Azure load balancer will remove instances from load balancer rotation that do not have a gateway on them. We still need to be careful that we do not unintentionally expose another service on these LB ports.

The following command can be used to deploy marathon-lb on the cluster. Run the command from the master or a client with appropriate ssh port forwarding configured.
```
curl https://raw.githubusercontent.com/flakio/infrastructure/master/marathon-lb.json | curl -qs -XPOST localhost:8080/v2/apps -d@- -H "Content-Type: application/json"
```

