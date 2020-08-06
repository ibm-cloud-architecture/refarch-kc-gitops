# refarch-kc-gitops

Event Driven Architecture reference implementation GitOps repository, in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Example environments

These example environments will deploy the microservices and their associated configuration to the `shipping` namespace.

### Development environment (`dev`)

This environment is deployable to any Kubernetes or OCP cluster and provides its own dedicated backing services.

Prerequisites:
- Strimzi operator must be installed, and configured to watch all namespaces.
- Appsody operator must be installed, and configured to watch all namespaces.
- Postgres database must exist. The defaults assume that the database is in the `postgres` namespace, configured with the default credentials (`postgres` / `supersecret`).

#### Postgres installation:
```
kubectl create ns postgres
kubectl create serviceaccount -n postgres pgserviceaccount
oc adm policy add-scc-to-user anyuid -z pgserviceaccount -n postgres
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql -n postgres --wait --timeout=300s --set postgresqlPassword=supersecret --set persistence.enabled=false --set serviceAccount.enabled=true --set serviceAccount.name=pgserviceaccount
```
(note: the `oc adm` command is required only if targeting an OpenShift cluster).

#### Deploying microservices:

One-time setup to create namespace and Kafka cluster:
```
kubectl apply -k environments/dev/infrastructure
kubectl wait --for=condition=ready kafka my-cluster --timeout 300s -n shipping
```
Deploy microservices and required configmaps and secrets:
```
kubectl apply -k environments/dev
```

### Environment with off-cluster backing services (`example-credentials`)

This example configures the microservices to connect to a Postgres database with SSL verification enabled, and to Event Streams using an API key.

The backing services should already exist (for example, hosted on an OpenShift cluster or IBM Cloud).  In the case of Kafka, the topics should already exist. In the `environments/example-credentials` tree, the Kafka topics are prefixed with `itg-integration-`.

Prerequisites: supply credentials for backing services as files - see [credentials README](./environments/example-credentials/env/base/credentials/README.md)
```
kubectl apply -k environments/example-credentials
```

### Environment with off-cluster Event Streams with certificates (`example-es-truststore`)

This example configures the microservices to connect to a Postgres database with SSL verification enabled, and to Event Streams using an API key, with SSL verification enabled. The ES certificate is provided as a Java truststore, or a PEM file to the non-Java apps.

Prerequisites: supply credentials for backing services as files - see [credentials README](./environments/example-es-truststore/env/base/credentials/README.md)
```
kubectl apply -k environments/example-es-truststore
```

## TODO: rewrite environment creation instructions below

## Deploying KContainer Reference Implementation using GitOps templates

1. Create a new branch based on the `starter-template` branch, using the format of `<namespace>/<clustername>`
   - Example: `git checkout starter-template && git checkout -b demo-sandbox/roks-demos.us-east.containers.appdomain.cloud`
2. Update the microservices' Route deployment YAMLs to contain an appropriate `host` value by uncommenting the lines and replacing the `[project]` and `[cluster-domain]` placeholder values.
   - Reference: [Red Hat OpenShift on IBM Cloud - Exposing apps that are inside your cluster to the public](https://cloud.ibm.com/docs/openshift?topic=openshift-ingress#ingress_expose_public)
   - Example: `kcontainer-ui-demo-sandbox.roks-demos.us-east.containers.appdomain.cloud`
3. Commit and push your updated branch to a git repository that will be accessible from your cluster.
4. Create all the necessary pre-requisites in the target cluster:
   1. Ensure ArgoCD is installed and functional. [Link](https://argoproj.github.io/argo-cd/getting_started/)
   2. Configure necessary backing components, like Kafka, Event Streams, or Postgresql. [Link](https://ibm-cloud-architecture.github.io/refarch-kc/deployments/backing-services/)
   3. Create necessary Kubernetes ConfigMaps and Secrets, which will connect the microservices to the backing components. [Link](https://ibm-cloud-architecture.github.io/refarch-kc/deployments/backing-services/)
      - The template YAMLs use the reasonable default names of the necessary ConfigMaps and Secrets, so the YAMLs will not need to be altered if you follow the deployment instructions exactly.
      - You may use different names for the ConfigMaps and Secrets, but you will need to adjust the references in the YAMLs accordingly.  This should only be necessary if deploying multiple times to the same namespace.
   4. Configure Service Account, as required by OpenShift or Kubernetes. [Link](https://ibm-cloud-architecture.github.io/refarch-kc/deployments/application-components/#openshift-container-platform-311)

5. Create an ArgoCD application deployment for each microservice you wish to deploy, using either the [ArgoCD CLI](https://argoproj.github.io/argo-cd/getting_started/#2-download-argo-cd-cli), applying application manifest YAMLs through the ArgoCD UI, or apply application manifest YAMLs through the Kubernetes CRDs:
   - ArgoCD CLI:
    ```bash
    argocd app create kcontainer-order-command-ms \
    --repo https://github.com/ibm-cloud-architecture/refarch-kc-gitops.git \
    --revision demo-sandbox/roks-demos.us-east.containers.appdomain.cloud \
    --path kc-ui --directory-recurse --dest-server https://kubernetes.default.svc \
    --dest-namespace demo-sandbox --sync-policy automated --self-heal --auto-prune
    ```
   - ArgoCD UI Manifest YAML:
    ```yaml
    project: default
    source:
      repoURL: 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops.git'
      path: kc-ui
      targetRevision: demo-sandbox/roks-demos.us-east.containers.appdomain.cloud
      directory:
        recurse: true
        jsonnet: {}
    destination:
      server: 'https://kubernetes.default.svc'
      namespace: demo-sandbox
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
    ```
   - ArgoCD CRD YAML:
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    metadata:
      name: kc-ui-ms
    spec:
      project: default
      source:
       repoURL: 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops.git'
       path: kc-ui
       targetRevision: demo-sandbox/roks-demos.us-east.containers.appdomain.cloud
       directory:
         recurse: true
         jsonnet: {}
      destination:
       server: 'https://kubernetes.default.svc'
       namespace: demo-sandbox
      syncPolicy:
       automated:
         prune: true
         selfHeal: true
    ```
5. You should be able to see ArgoCD applying the YAMLs to the target cluster by watching `kubectl get pods`.
6.  Validate all application `Status` conditions are both `Healthy` and `Synced` before verifying your application deployment in the application UI.


### Generating KContainer Reference Implementation GitOps templates

1. Generate all your necessary Kubernetes YAMLs by following the deployment steps documented in https://ibm-cloud-architecture.github.io/refarch-kc/deployments/application-components/, passing in specific values for the desired configuration.
2. Copy the generated YAMLs to the root of your new branch in the repository.
   - Example: `<repo_root>/ordercommandms/templates`
3. Commit and push your generated YAMLs to this repository on your new branch.  _Note that the `master` branch is protected and will not accept pushes, so you will only be able to push to your branch._
4. Continue with [Templates Step #4](#deploying-kcontainer-reference-implementation-using-gitops-templates) above.
5.  Validate all application `Status` conditions are both `Healthy` and `Synced` before verifying your application deployment in the UI.
