# ghcr-app glue for flux

(Reminder: with no kustomization file present, flux will autogenerate one)

Purpose of this directory is two-fold:

1. link in the flux config repo via gitops, instead of a manual call to
   flux create kustomization

2. automatically update to use the latest tag version for the image referenced.

