# fluxcd-starterkit

This repo is a specially cleaned up version of a working flux cluster state repo,
WITH a sample auto-updater gitops pipeline all tested and ready to go.


In a [different repo](https://github.com/ppbrown/fluxcd-public-demo), 
I have a zero-touch flux demo, for people who dont want
to deal with setting up Git Tokens for access, etc. 
However, that approach is somewhat limited. It cant do some of the fancy stuff
like auto-updating, since that requires giving flux access to WRITE to the repo.

On the flip side, that typically means you may end up writing secrets to the repo,
which then makes it a very bad thing to share publically.

That is why THIS repo exists.


# Prerequisites

## Kubernetes

Install a kubernetes cluster.  For a 1-node quickstart Ubuntu, you could use 

    curl -sfL https://get.k3s.io | sh - 
    # you then either need to give yourself cluster access or run as root

## Install flux binary

    curl -s https://fluxcd.io/install.sh | sudo bash


# FluxCD Install instructions

## Repo preparations

Here are step-by-step instructions on how to get FluxCD up and running with this setup.

First you will need to fork (not clone!) this repo, since you need a repo you can write to!

Let's say you fork it to `yourname/fluxcd-starterkit`

MAKE IT PRIVATE RIGHT NOW!! DO NOT GO FURTHER UNTIL YOU HAVE FIXED THIS!!

Next, make a github access token that has full read/write to your new repo.

After that, you probably will want to fork (not clone!) the target repos so you can
experiment with auto-updates yourself. These are:

* https://github.com/ppbrown/fluxcd-ghcr-app
* https://github.com/ppbrown/ghcr-test

If you do a straight fork, then you will need to edit one file in your own repo to change
`ppbrown` to `yourname`:

- fluxcd-ghcr-app/deployment.yaml

you will also need to make sure that you generated a new image to pull. 
Go look at

    https:/ghcr.io/yourname/ghcr-test

If there's nothing there then you have to trigger a build by pushing a new number to
https://github.com/yourname/ghcr-test/blob/main/deploytest_tag

## Starting up Flux!

(make sure you have exported `GITHUB_TOKEN` with the secret value first!!)

    flux bootstrap github  --owner=yourname --repository=fluxcd-starterkit \
      --token-auth --personal \
      --components-extra=image-reflector-controller,image-automation-controller \
    # if you are doing this with an "Org" type account, omit the --personal

and now... wait a few minutes!

It should take a few minutes for flux to insert its services into the cluster, and then
a few more minutes for it to read the actual app configuration, and start pulling in
the image.

At this point you should be able to see the service running:

    # kubectl -n ghcr-app get svc
    NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    ghcr-app   ClusterIP   10.43.188.108   <none>        8080/TCP   23h

    # kubectl port-forward -n ghcr-app  service/ghcr-app  8080

At that point, you should be able to point your webbrowser at http://localhost:8080
and see output from it.

But then, after that point, if you edit and push the number in repo 
`yourname/ghcr-test/deploytest_tag` to a larger number... github will autobuild a new
image. Then a few minutes later, flux scanning will notice a newer image, and update
its configs. And a few minutes after that, it will trigger a redeploy of the app with the
newer image.


