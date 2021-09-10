# refarch-kc-gitops

Event Driven Architecture reference implementation GitOps repository, in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Integration environment (`eda-integration`)

This environment is deployable to any Kubernetes or OCP cluster and provides its own dedicated backing PostgreSQL service. It expects an external IBM Event Streams on Cloud instance.

### Prerequisites

- [Appsody operator](https://operatorhub.io/operator/appsody-operator) must be installed, and configured to watch all namespaces.
- [OpenLiberty operator](https://operatorhub.io/operator/open-liberty) must be installed, and configured to watch all namespaces.
- The Kafka Topics defined in the [`kafka-topics-configmap.yaml`](env/base/kafka-topics-configmap.yaml) must be created on the remote IBM Event Streams on Cloud instance manually.

### Environment setup

```
kubectl create ns eda-integration
kubectl create serviceaccount -n eda-integration kcontainer-runtime
kubectl create secret generic eventstreams-cred --from-literal=username=token --from-literal=password={API_KEY}
oc adm policy add-scc-to-user anyuid -z kcontainer-runtime -n eda-integration
```

**NOTES:**
- The `oc adm` command is required only if targeting an OpenShift cluster).
- Replace `{API_KEY}` with your IBM Event Streams on Cloud API Key.

### Deploying microservices manually

This example configures the microservices to connect to a Postgres database with SSL verification enabled and to IBM Event Streams on Cloud using an API key.

The backing services should already exist (for example, hosted on an OpenShift cluster or IBM Cloud).  In the case of Kafka, the topics should already exist. In the `environments/eda-integration-2021.1` tree, the Kafka topics are prefixed with `eda-integration-`.

```
kubectl apply -k environments/eda-integration-2021.1
```

### Deploying microservices via ArgoCD

TBD
