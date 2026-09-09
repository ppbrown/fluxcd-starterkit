# ghcr-app glue for flux

Purpose of this directory is two-fold:

1. link in the flux config repo via gitops, instead of a manual call to
   flux create kustomization

2. automatically update to use the latest tag version for the image referenced.

The `ImageRepository`/`ImagePolicy` pair needed for (2) isn't defined here
directly. It's pulled in from the shared
[`templates/image-automation`](../../templates/image-automation) component and
patched with this app's name/image in `kustomization.yaml`, so adding another
app doesn't mean copy-pasting those files again. See that component's README
for the pattern.

The `ImageUpdateAutomation` for (2) isn't per-app at all — there's one shared
instance for the whole repo at
[`prod/image-update-automation.yaml`](../image-update-automation.yaml).

