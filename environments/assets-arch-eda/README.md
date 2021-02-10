# refarch-kc-gitops

Event Driven Architecture reference implementation GitOps repository, in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Integration environment (`eda-integration`)

This environment is deployable to any Kubernetes or OCP cluster and provides its own dedicated backing Kafka cluster and PostgreSQL service.

### Prerequisites

- [Appsody operator](https://operatorhub.io/operator/appsody-operator) must be installed, and configured to watch all namespaces.
- [OpenLiberty operator](https://operatorhub.io/operator/open-liberty) must be installed, and configured to watch all namespaces.
- [Strimzi operator](https://operatorhub.io/operator/strimzi-kafka-operator) must be installed, and configured to watch all namespaces.

### Environment setup

```shell
kubectl create ns eda-integration
kubectl create serviceaccount -n eda-integration kcontainer-runtime
oc adm policy add-scc-to-user anyuid -z kcontainer-runtime -n eda-integration
```

**NOTES:**
- The `oc adm` command is required only if targeting an OpenShift cluster).

### Deploying microservices manually

This example configures the microservices to connect to a local Postgres database and and local Kafka cluster, both of which are development-grade services. The Kafka cluster is secured by auto-generated SCRAM-SHA-512-based credentials.

**Deploy the backing Kafka cluster**
```shell
kubectl apply -k environments/assets-arch-eda/infrastructure
oc wait --for=condition=ready kafka my-cluster --timeout 300s
```

**Deploy the application configuration and microservices**
```shell
kubectl apply -k environments/assets-arch-eda
sleep 10
oc wait --for=condition=available deploy -l app.kubernetes.io/part-of=refarch-kc --timeout 300s
```

### Deploying microservices via ArgoCD

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) is the preferred continuous delivery tool for GitOps-based application configuration. You can install ArgoCD through the deployment of the [IBM Cloud Native Toolkit](https://cloudnativetoolkit.dev/) or the [ArgoCD Operator](https://operatorhub.io/operator/argocd-operator).

1. Create `refarch-kc` project
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: AppProject
    metadata:
      name: refarch-kc
    spec:
      description: Integration project for refarch-kc-gitops project
      destinations:
        - namespace: eda-integration
          server: 'https://kubernetes.default.svc'
      sourceRepos:
        - 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops'

    ```

1. Create `infrastructure` application _(this needs to be created prior to the `application` components, as the component microservices behave differently if the Kafka broker is not available at startup)_
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: refarch-kc-infrastructure
    spec:
      destination:
        namespace: eda-integration
        server: https://kubernetes.default.svc
      project: refarch-kc
      source:
        path: environments/assets-arch-eda/infrastructure
        repoURL: https://github.com/ibm-cloud-architecture/refarch-kc-gitops
        targetRevision: HEAD
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
    ```

1. Create `application` application
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: refarch-kc-application
    spec:
      destination:
        namespace: eda-integration
        server: 'https://kubernetes.default.svc'
      source:
        path: environments/assets-arch-eda
        repoURL: 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops'
        targetRevision: HEAD
      project: refarch-kc
      syncPolicy:
        automated:
          automated:
            prune: false
            selfHeal: false
          prune: true
          selfHeal: true
    ```

### Accessing the deployed Kafka instance

1. Extract `sasl.jaas.config` from KafkaUser secret via the following `oc` command:
   ```shell
   oc get secret eda-integration-kafka-user -o jsonpath="{ .data.sasl\.jaas\.config }" | base64 -d -
   ```
1. Extract the external endpoint via the following `oc` command:
   ```shell
   KAFKA_BOOTSTRAP=$(oc get route my-cluster-kafka-bootstrap -o jsonpath="{ .status.ingress[0].host }:443")
   ```
1. Extract the public certificate keystore of the Kafka cluster via the following `oc` command:
   ```shell
   oc get secret my-cluster-cluster-ca-cert -o jsonpath="{ .data.ca\.p12 }" | base64 -d - > ca.p12
   echo "$(pwd)/ca.p12"
   ```
1. Extract the public certificate password of the Kafka cluster via the following `oc` command:
   ```shell
   oc get secret my-cluster-cluster-ca-cert -o jsonpath="{ .data.ca\.password }" | base64 -d -
   ```
1. Create `endpoint-config.properties`
   ```properties
   sasl.jaas.config=___REPLACE_WITH_YOUR_SASL_JAAS_CONFIG___
   security.protocol=SASL_SSL
   sasl.mechanism=SCRAM-SHA-512
   ssl.protocol=TLSv1.2
   ssl.enabled.protocols=TLSv1.2
   ssl.endpoint.identification.algorithm=HTTPS

   ssl.truststore.location=___REPLACE_WITH_YOUR_ABSOLUTE_PATH_TO_EXPORTED_CA.P12___
   ssl.truststore.password=___REPLACE_WITH_YOUR_CA.PASSWORD___
   ```
1. Download the latest [Kafka binaries](http://kafka.apache.org/downloads) or utilize a pre-built Kafka container image.
1. Execute `bin/kafka-console-consumer.sh` via the following command:
   ```shell
   bin/kafka-console-consumer.sh --bootstrap-server ${KAFKA_BOOTSTRAP} --consumer.config /absolute/path/to/your/endpoint-config.properties --from-beginning --topic assets-arch-eda-orders
   ```
