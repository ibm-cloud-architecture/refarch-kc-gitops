# refarch-kc-gitops
Event Driven Architecture reference implementation GitOps repository

GitOps implementation in support of https://ibm-cloud-architecture.github.io/refarch-eda/

## Deploy K-Container reference implementation via GitOps

**Pre-requisite**: Deployed ArgoCD in a cluster

1. Clone this repository.
2. Create a branch in this repository in the form of `<namespace>/<cluster_name>`.
  - Example: `git checkout -b eda-demo/c100-e-us-east-containers-cloud-ibm-com`
3. Generate all your necessary Kubernetes YAMLs by following the deployment steps documented in https://ibm-cloud-architecture.github.io/refarch-kc/deployments/application-components/, passing in specific values for the desired configuration.
4. Copy the generated YAMLs to the root of your new branch in this repository.
  - Example: `<repo_root>/ordercommandms/templates`
5. Commit and push your generated YAMLs to this repository on your new branch.  Note that the `master` branch is protected and will not accept pushes, so you will only be able to push to your branch.
6. Create the applications inside of ArgoCD, using either the ArgoCD UI or the ArgoCD CLI.
  - ArgoCD UI can use an application manifest similar to the following:
  ```
  project: default
  source:
    repoURL: 'https://github.com/ibm-cloud-architecture/refarch-kc-gitops.git'
    path: <microservice_name>
    targetRevision: <branch_name>
    directory:
      recurse: true
      jsonnet: {}
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: <target_namespace>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
  - ArgoCD CLI can create the same application with the following command:
  ```
  argocd app create kcontainer-order-command-ms --repo https://github.com/ibm-cloud-architecture/refarch-kc-gitops.git --revision eda-demo/c100-e-us-east-containers-cloud-ibm-com --path ordercommandms --directory-recurse --dest-server https://kubernetes.default.svc --dest-namespace eda-demo --sync-policy automated --self-heal --auto-prune
  ```
7.  Validate all application `Status` conditions are both `Healthy` and `Synced` before verifying your application deployment in the UI.
