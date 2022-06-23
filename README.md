<!-- markdownlint-configure-file {
  "MD013": {
    "code_blocks": false,
    "tables": false
  },
  "MD033": false,
  "MD041": false
} -->

<div align="center">

# Algolia Instant Search Demo

This is a sample project of an [Algolia](http://www.algolia.com) Instant-Search result page on an e-commerce website. Algolia is a Search API that provides a hosted full-text, numerical and faceted search.

[Installation](#installation) •
[Result](#result) •
[Continuous Improvement](#continuos-improvement)


</div>

# Getting Started

For this demo, Algolia Instant Search API is packaged using Helm and continuously deployed on GKE through GitHub Actions.

# Installation

## Current Infrastructre

I already have an existent cluster that I've created to PoC and test new tools on Kubernetes.

1. GKE cluster
        <details>
        <summary>config</summary>
    - All components created via Terraform ( VPC, GKE, IAM ) 
        </details>
2. Cert-Manager
        <details>
        <summary>config</summary>
    - Based on `https://charts.jetstack.io` 1.6.1 Chart
    - Cluster Issuer
    - Wildcard Certificate
    - Configured with Workload Identity
        </details>
3. Nginx Ingress Controller
        <details>
        <summary>config</summary>
    - Based on `https://kubernetes.github.io/ingress-nginx` 4.0.13 Chart
    - Default SSL Certificate: `default-ssl-certificate: "cert-manager/example-wildcard-secret"`
        </details>
4. Cloud DNS
        <details>
        <summary>config</summary>
    - With Private Zone
        </details> 
5. Cloud Load Balancer
        <details>
        <summary>config</summary> 
    - With Static External IP
        </details>

## Demo Architecture

![Architecture](/docs/images/demo-architecture.png)

## Demo CI/CD
Development, Test and Deployment workflows always need to be designed based on Developers needs, since they are the main stakeholders. </br>

For this Demo, we considered the merge on default branch use case.

We created a CI workflow that:
1. On merge to the main branch, we create a semantic version and publish a new release
2. Build a new container image based on the recent release
3. Push the new container image to Docker Hub
4. Update the Chart appVersion
5. Commit and Push to the main branch

Then, the CD workflow:
1. Triggered if a change happened on the Chart folder
2. Authenticate to GKE cluster

3. Install the Chart, with --wait to make sure all new Pods and running.

In order to reuse workflows, please replace environment variables and secrets with your own parameters. </br>
Keep in mind:
- `PAT` is your Personal GitHub Acces Token with repo and workflows permissions, since the default `secrets.GITHUB_TOKEN` doesn't trigger Actions.
- `GKE_SA` is the GKE SA Key in base64 to authenticate to the cluster
    <details>
    <summary>How to</summary>
    Create a new service account:

    ```sh
    gcloud iam service-accounts create $SA_NAME
    ```

    Get the email of the newly create service account:

    ```sh
    gcloud iam service-accounts list |grep $SA_NAME
    ```

    Add container.admin role to the service account:

    ```sh
    gcloud projects add-iam-policy-binding $GKE_PROJECT \
	--member=serviceAccount:$SA_EMAIL \
	--role=roles/container.admin
    ```

    Download the service account json key:

    ```sh
    gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL
    ```

    Retrieve its json key as base64:
    ```sh
    export GKE_SA=$(cat key.json | base64)
    ```
    </details>

## Deployment and Resiliency

### Kubernetes level

1. Kept the default Strategy `Rolling Update` to make sure new Pods are up and running before redirecting traffic.

2. Defined an `HPA` of minimum `3 replicas` and maximum `5 replicas` to ensure High Availabilty.

3. Created a `Pod Disruption Budget` to make sure only 1 Pod is unavaible during a reschedule.

4. Assigned the `Burstable QoS` ( not `Guranateed` because we don't know the exact limits ), to make sure `kubelet` doesn't evict Pods immediatly.

5. Specified a `podAntiAffinity` to make sure Pods are not deployed on the same host to prevent disruption during node failures.

### Helm level

1. Set the `--wait` flag, along with `testing-connection` `"helm.sh/hook": test-success` to only consider the release as successfully deployed when all new Pods are running.

# Result

- Build workflow successfuly finished
![Build](/docs/images/build-workflow.png)

- Deploy workflow successfuly finished
![Deploy](/docs/images/deploy-workflow.png)

- Up and Running Pods
![Running Pods](/docs/images/pods.png)

- Ingress, with tls
![Ingress](/docs/images/ingress-tls.png)


# Continuous Improvement

1. Create a CI/CD workflow that helps Developers test their code before merge.
2. Integrate continuous container image scanning in the build workflow.
3. Build a rootless container image and use Kubernetes security context.
4. Move base images to an internal registry to avoid Docker Hub pull rates.
5. Package and push Helm Chart to a Helm repository.
6. Implement Helm post-upgrade hooks to efficiently test new releases.
