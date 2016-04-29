#Flak.io Infrastructure

## Configuration
Managing configuration

## Management
After provisioning a new Mesos cluster using the Azure Container Service (ACS) mesos orchestrator option, we can connect with ssh client with port forwarding setup and agent forwarding.

`ssh {user}@{dnslabel}mgmt.westus.cloudapp.azure.com -A -p 2200 -L 8080:localhost:8080 -L 5050:master.mesos:5050 -L 4400:localhost:4400`

The `-L` options forward local ports to endpoints and ports on the target system. Mesos master is not listening on local host so we need to use the master IP address instead. The `-A` option enables agent forwarding and allows us to connect to other systems in the cluster.

Current deployments of ACS mesos orchestrator include a proxy for connecting to the various framework UI.  We only need to forward one port using the following `ssh -L 8080:localhost:80 -N trent@trentestmgmt.westus.cloudapp.azure.com -p 2200`, and then we can connect to the various frameworks using `http://localhost:8080/marathon` for example.

## Marathon-lb - marathon-ilb / internal
A marathon-lb instance is deployed to handle routing internal traffic for our services to the appropriate service instances.

The following command can be used to deploy marathon-lb in the cluster. Run the command from client with appropriate ssh port forwarding configured.
```
curl https://raw.githubusercontent.com/flakio/infrastructure/master/marathon-lb.json | curl -qs -XPOST localhost:8080/marathon/v2/apps -d@- -H "Content-Type: application/json"
```
### services (with marathon-lb deployments)
- 10000 frontend
- 10001 catalog service
- 10002 order service
- 10003 order service database

### services (with minuteman deployments)
- 192.168.1.1:80 frontend
- 192.168.2.1:80 catalog service
- 192.168.3.1:80 order service
- 192.168.3.2:80 order service database

## Gateway
An NGINX gateway is used for routing external traffic from the Azure load balancers to the correct internal marathon-lb service port. We will deploy two instances in the load balancer and rely on the fact that the Azure load balancer will remove instances from load balancer rotation that do not have a gateway on them.

The following command can be used to deploy marathon-lb on the cluster. Run the command from the master or a client with appropriate ssh port forwarding configured.
```
curl https://raw.githubusercontent.com/flakio/infrastructure/master/gateway/marathon.json | curl -qs -XPOST localhost:8080/marathon/v2/apps -d@- -H "Content-Type: application/json"
```
