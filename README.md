# opa-envoy-tut

This repo is based on the Open Policy Agent [Stand-alone Envoy Tutorial](https://www.openpolicyagent.org/docs/latest/envoy-tutorial-standalone-envoy/)

For the rego policy files solving the excersize see directory ./rego-task and its README.md for the details

For the the kubernetes-based implementation read below.

The rest of the page assumes you run through it on the Mac.


# Real-world scenrio

To make it more realistic we will assume that we are adding policy-based authorization to an existing cloud-native application

We assume that kustomize is used to deploy the application with environment specific settings (such as namespace,  ingress hostname etc.)

for simplicity we'll be using nio.io dynamic DNS and will store ingress LoadBalancer service public IP address in an environment variable $SERVICE_HOST.

## Prerequisites

1. k8s cluster 
2. kubectl with kubeconfig pointing to the k8s cluster

### Setup basic nginx ingress

```sh
# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# namespace for the iongress controller
kubectl create namespace ingress-basic

#run helm chart
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-basic --set controller.replicaCount=2 --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux   --set controller.service.externalTrafficPolicy=Local
```

Let's also store public IP of our ingress to use later:

```sh
export INGRESS_IP=$(kubectl get service nginx-ingress-ingress-nginx-controller -n ingress-basic -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

# Integrating OPA Authorization into a Sample Application

[Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/) is one of the most popular tools to deploy applications consisting of multiple manifest files and overlays. So our example we'll show how easy it is to integrate OPA Authorization with Kustomize

Directory k8s/kustomize contains our example.

## Where to start: bare-bone application manifest files

'app' directory includes manifest files for deploying 'example-app' application:

- deployment
- ClusterIP-based service
- nginx-based ingress

and a kustomization file 'kustomuze.yaml'

This is the bare-bone appl install without namespace or any policy ingection

## Adding OPA authorization

'app-w-policy' directory includes kustomization:

- config map based on envoy.yaml file 
- secret that contains policy.rego (there is not much of a secret there, so it's OK to keep it in git as part of configuration
- strategic merge patch to the deployment that adds init container and envoy and opa sidecar containers and their volume-based intialization with the configmap and the secret descrivebed above

This kustomization doesn't assume anothing about an namespace or a ingress host/url where our example-app application is published

## Finally, deployment overlays

It is customary the same k8s cluster hosts multiple instances of our application, - dev, sandbox, preprod, etc. Typically they are isolated in their own namespace.

We will be using 2 instances: sandbox and preprod. The kustomizations for preprod and sandbox are located in 'overlays/sandbox' and 'overlays/preprod' folders. Each of them uses ' app-w-policy ' as a base and redefine host for the ingress and a namespace where application components are deployed.


And the sandbox will have a different versions of a OPA Authorization policy. In the sandbox we replace .rego policy file. This updated policy gives permission to DELETE for the 'admin' users. We will test it below.

## Deploy sandbox and preprod instances of our example-app

First, create namespaces:

```sh
kubectl create namespace opa-envoy-tut-sandbox
kubectl create namespace opa-envoy-tut-preprod
```

Next, deploy customizations:

```
cd ./k8s/kustomize
kubectl apply -k overlays/preprod
kubectl apply -k overlays/sandbox
```

Next, define ingress domain suffixes for each instance and store them in the ENV:

```sh
export PREPROD_SUFFIX=opa-envoy-tut-preprod
export SANDBOX_SUFFIX=opa-envoy-tut-sandbox
```

We are ready to test our auth policy

## Running queries with httpie

To test our deployments we'll use CLI tool called [httpie](https://httpie.io/).
Install using homebrew: ' brew install httpie '

To reduce repetitive typing prepare ENV variables for JWT tokens:
```sh
export ALICE_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiZ3Vlc3QiLCJzdWIiOiJZV3hwWTJVPSIsIm5iZiI6MTUxNDg1MTEzOSwiZXhwIjoxNjQxMDgxNTM5fQ.K5DnnbbIOspRbpCr2IKXE9cPVatGOCBrBQobQmBmaeU"
export BOB_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjE2NDEwODE1Mzl9.WCxNAveAVAdRCmkpIObOTaSd0AJRECY2Ch2Qdic3kU8"
```

We'll test preprod instance first:

```sh
export SERVICE_URL=$PREPROD_SUFFIX.$INGRESS_IP.nip.io
echo $SERVICE_URL
```

Finally let's use http to test policy:

```sh
http GET http://$SERVICE_URL/people "Authorization:Bearer $ALICE_TOKEN"
http GET http://$SERVICE_URL/people "Authorization:Bearer $BOB_TOKEN"
http POST http://$SERVICE_URL/people "Authorization:Bearer $BOB_TOKEN"  firstname=Charlie lastname=OPA
http POST http://$SERVICE_URL/people "Authorization:Bearer $BOB_TOKEN" firstname=Bob lastname=OPA
```

Now let's test our policy update that enabled admins to make DELETE API calls:

Both Alice and Bob should get 403 as DELETE operation is not allowed by the policy:
```sh
http DELETE http://$SERVICE_URL/people/0 "Authorization:Bearer $ALICE_TOKEN"
http DELETE http://$SERVICE_URL/people/0 "Authorization:Bearer $BOB_TOKEN"
```

## Checking out DELETE operation in the sandbox environment

Let's point $SERVICE_URL to the sanbox ingress:

```sh
export SERVICE_URL=$SANDBOX_SUFFIX.$INGRESS_IP.nip.io
echo $SERVICE_URL
```

In the sandbox Alice call should fail, but Bob's call should succees:

```sh
http DELETE http://$SERVICE_URL/people/0 "Authorization:Bearer $ALICE_TOKEN"
http DELETE http://$SERVICE_URL/people/0 "Authorization:Bearer $BOB_TOKEN"
```
