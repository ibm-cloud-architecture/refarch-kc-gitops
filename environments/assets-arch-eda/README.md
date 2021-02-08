# refarch-kc-gitops

Event Driven Architecture reference implementation GitOps repository, in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Integration environment (`eda-integration`)

This environment is deployable to any Kubernetes or OCP cluster and provides its own dedicated backing Kafka cluster and PostgreSQL service.

### Prerequisites

- [Appsody operator](https://operatorhub.io/operator/appsody-operator) must be installed, and configured to watch all namespaces.
- [OpenLiberty operator](https://operatorhub.io/operator/open-liberty) must be installed, and configured to watch all namespaces.
- [Strimzi operator](https://operatorhub.io/operator/strimzi-kafka-operator) must be installed, and configured to watch all namespaces.

### Environment setup

```
kubectl create ns eda-integration
kubectl create serviceaccount -n eda-integration kcontainer-runtime
oc adm policy add-scc-to-user anyuid -z kcontainer-runtime -n eda-integration
```

**NOTES:**
- The `oc adm` command is required only if targeting an OpenShift cluster).

### Deploying microservices manually

This example configures the microservices to connect to a local Postgres database and and local Kafka cluster, both of which are development-grade services. The Kafka cluster is secured by auto-generated SCRAM-SHA-512-based credentials.

**Deploy the backing Kafka cluster**
```
kubectl apply -k environments/assets-arch-eda/infrastructure
oc wait --for=condition=ready kafka my-cluster --timeout 300s
```

**Deploy the application configuration and microservices**
```
kubectl apply -k environments/eda-integration-2021.1
sleep 10
oc wait --for=condition=available deploy -l app.kubernetes.io/part-of=refarch-kc --timeout 300s -n shipping
```

### Deploying microservices via ArgoCD

TODO
1. Create `infrastructure` project
2. Create `application` project
