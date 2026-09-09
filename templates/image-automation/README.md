# image-automation component

Shared Kustomize [Component](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/components/)
providing the two CRs every image-auto-updating app needs, one per app:

- `imagerepository.yaml` (`ImageRepository`)
- `imagepolicy.yaml` (`ImagePolicy`)

An app pulls this component in and patches just the fields that are actually
app-specific: its name, and the image it tracks.

Note: `ImageUpdateAutomation` is *not* part of this component. It isn't
per-app data — one instance, defined once at
[`prod/image-update-automation.yaml`](../../prod/image-update-automation.yaml),
scans the whole `./prod` tree for `{"$imagepolicy": ...}` markers and
git-commits tag bumps for every app's `ImagePolicy`. Adding a new app never
requires touching it.

## Usage

In `prod/<app>/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - source.yaml
  - <app>.yaml
components:
  - ../../templates/image-automation
patches:
  - target:
      kind: ImageRepository
    patch: |
      - op: replace
        path: /metadata/name
        value: <app>
      - op: replace
        path: /spec/image
        value: <image-ref>
  - target:
      kind: ImagePolicy
    patch: |
      - op: replace
        path: /metadata/name
        value: <app>
      - op: replace
        path: /spec/imageRepositoryRef/name
        value: <app>
```

`target: {kind: ...}` matches by kind alone, which is fine as long as each
app directory only pulls the component in once (i.e. one ImageRepository /
ImagePolicy per app dir). And make sure `<app>.yaml`'s `# {"$imagepolicy":
"flux-system:<app>:tag"}` marker comment uses the same `<app>` name.

Everything else (interval, filterTags pattern, numeric tag policy) is a
shared default defined once here. If a given app needs a different tag
filter or policy, add another `replace` (or `add`) op to that app's
`ImagePolicy` patch — no need to fork the whole file.
