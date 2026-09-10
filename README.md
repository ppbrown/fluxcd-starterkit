# fluxcd-starterkit

* What does this repo give you?

An instance of the Flux CD orchestration tool set up in a kubernetes
cluster, fconfigured with a sample application to demonstrate full GitOps style
"Auto update deployment on application publish"

Some assembly required, but dont worry, I have step-by-step instructions for you, and they
are *wayyy* shorter than the 20 pages of docs on the official flux-cd site.

Even simpler, I now provide a

    [install.sh](install.sh)

script that can do everything except set up a kubernetes cluster for you, and create
the GH credential. But if you'd like to see the details, please read on.


# Prerequisites

## Kubernetes

If you dont already have one, you will need to install a kubernetes cluster.
For a 1-node quickstart on Ubuntu, you could use 

    curl -sfL https://get.k3s.io | sh - 
    # You then either need to give yourself cluster access or run as root

## Install the 'flux' binary

    curl -s https://fluxcd.io/install.sh | sudo bash


# FluxCD Install instructions

You have the binary, but now we must set up the services.

## Repo preparations

First you will need to fork (not clone!) this repo, since you need a repo Flux can write
to!

Let's say you fork it to `yourname/fluxcd-starterkit`

MAKE IT PRIVATE RIGHT NOW!! DO NOT GO FURTHER UNTIL YOU HAVE FIXED THIS!!

Next, make a github access token (AKA Personal Access Token, "PAT") that has full
read/write to your new repo.


## Backend repos

Unless you already know a little about flux setup and have your own repos, you will
probably want to use my related ones as a head start.

Fork (not clone!) the target repos below so you can experiment with auto-updates yourself. 

* https://github.com/ppbrown/fluxcd-ghcr-app
* https://github.com/ppbrown/ghcr-test

Then you will need to edit one file in your own repo to change `ppbrown` to `yourname`:

- fluxcd-ghcr-app/deployment.yaml

You will also need to make sure that you generated a new image to pull. 
Go look at

    https:/ghcr.io/yourname/ghcr-test

If there's nothing there then you have to trigger a build by pushing a new number to
https://github.com/yourname/ghcr-test/blob/main/deploytest_tag

## Starting up Flux!

(make sure you have exported `GITHUB_TOKEN` with the secret value first!!)

    flux bootstrap github  --owner=yourname --repository=fluxcd-starterkit \
      --token-auth --personal \
      --components-extra=image-reflector-controller,image-automation-controller 
    # if you are doing this with an "Org" type account, omit the --personal

And now... wait a few minutes!

It should take a few minutes for flux to insert its services into the cluster, and then
a few more minutes for it to read the actual app configuration, and start pulling in
the image.

At this point you should be able to see the service running:

    # kubectl -n ghcr-app get svc
    NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    ghcr-app   ClusterIP   10.43.188.108   <none>        8080/TCP   23h


To directly view in browser, one way is to set up port forwarding for
http://localhost:8080

    # kubectl port-forward -n ghcr-app  service/ghcr-app  8080

### Semi-permanent access (skip the port-forward)

The downside with port forwarding, other than hogging a terminal, is that it fails on
service restart.

A way around this is to set up loadbalancer style forwarding on your test node 

    kubectl expose service ghcr-app -n ghcr-app \
      --type=LoadBalancer --name=ghcr-app-lb --port=8080

Find the right IP address to hit, with `kubectl -n ghcr-app get svc ghcr-app-lb` for
the EXTERNAL-IP, and browse to `http://<that-ip>:8080` (not `localhost`).



