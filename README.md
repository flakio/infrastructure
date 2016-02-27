#Flak.io Infrastructure

## Configuration
Managing configuration

## Management
After provisioning a new ACS cluster wiht the mesos orchestrator, we can connect with ssh client with port forwarding setup and agent forwarding.

`ssh azureuser@dockmgmt.uswest.cloudapp.azure.com -A -p 2200 -L 8080:localhost:8080 -L 5050:mesos.master:5050 -L 4400:mesos.master:4400`

The `-L` options forward local ports to endpoints and ports on the target system. Mesos is not listening on local host so we need to use the master IP address instead.  The `-A` option enables agent forwarding and allows us to connect to other systems in the cluster.

## Gateway
The applicaiton/api gateway is used to route or proxy inbound requests to the various services in the cluster.  This must be deployed to all nodes handling Azure laod balancer requests in a mesos marathon cluster.

The gateway application can be deployed using the following command
```curl -s -XPOST localhost:8080/v2/apps -d@marathon-gateway.json -H "Content-Type: application/json"```

You should note that you may need to adjust the instance counts and/or constraints to ensure an instance of the gateway is running on all nodes that load balancer is configured to route traffic to.

__Note:__ This will be replace with Marathon-LB
