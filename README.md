#Flak.io Infrastructure

## Configuration
Managing configuration

## Gateway
The applicaiton/api gateway is used to route or proxy inbound requests to the various services in the cluster.  This must be deployed to all nodes handling Azure laod balancer requests in a mesos marathon cluster.

The gateway application can be deployed using the following command
```curl -s -XPOST localhost:8080/v2/apps -d@marathon-gateway.json -H "Content-Type: application/json"```

You should note that you may need to adjust the instance counts and/or constraints to ensure an instance of the gateway is running on all nodes that load balancer is configured to route traffic to.
