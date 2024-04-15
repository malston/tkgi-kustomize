# Multi-foundation, Multi-cluster TKGi Kustomize Example

This repository shows an example of how to use [Kustomize](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/) bases and overlays to maintain manifests for applications that need to be deployed to multiple clusters across multiple foundations.

Bases are kustomizations that contain common configurations. Overlays are kustomizations that overlay on top of bases. Overlays apply configurations on top of bases or on top of other overlays.

This example has multiple bases, one per application: [bitnami-wordpress](bases/bitnami-wordpress/) and [guestbook](bases/guestbook/). The `bitnami-wordpress` app is a [helm chart](https://bitnami.com/stack/wordpress/helm) while the [guestbook](https://docs.vmware.com/en/VMware-Cloud-Foundation/services/vcf-developer-ready-infrastructure-v1/GUID-6F184EC5-AFC1-4D0A-A5D5-1E31EE938438.html) app is a simple Javascript app that uses MongoDB for it's backend. 

One thing to take note of -- although the [bases](bases/) folder is checked into this repository, under normal circumstances, unless these apps were maintain by the Platform Engineering team, they would be in separate repositories. You can include bases from another repository like this:

```yaml
resources:
- github.com/malston/kustomize-apps/apps/bitnami-wordpress/base?ref=main
```

In overlays, we have a single `foundations` folder containing all the lab foundation TKGi clusters.

 1. `foundations`: We have one folder per TKGi cluster nested inside a folder for each foundation.

Adopting a repository structure like this to manage multiple foundations makes it intuitive to understand where certain changes should be made while reducing the amount of configuration to maintain across clusters.

## Deploy

Under normal circumstances, we want to deploy to a single cluster. In this case, [cluster01](overlays/foundations/dc01-fd01/cluster01/kustomization.yaml) in [dc01-fd01](overlays/foundations/dc01-fd01/kustomization.yaml). This will apply our configurations at both the foundation and cluster level that we want to overlay over the base of all the apps we want to deploy to that cluster.

### Deploy K8s Resource Manifests to cluster01 in dc01-fd01

```console
kubectl kustomize --enable-helm --helm-command helm \
  overlays/foundations/dc01-fd01/cluster01 | \
  kubectl apply -f -
```

## Build

We assume you're using a GitOps operator to deploy to the cluster. But if you wanted to deploy to multiple clusters at once, you'd need to be logged-in to each of those clusters. So you might have a script that first built all the manifests into a directory structure like this:

```console
manifests
├── dc01-fd01
│   ├── cluster01
│   │   └── allinone.yaml
│   └── cluster02
│       └── allinone.yaml
├── dc01-fd02
│   ├── cluster01
│   │   └── allinone.yaml
│   └── cluster02
│       └── allinone.yaml
├── dc02-fd01
│   ├── cluster01
│   │   └── allinone.yaml
│   └── cluster02
│       └── allinone.yaml
└── dc02-fd02
    ├── cluster01
    │   └── allinone.yaml
    └── cluster02
        └── allinone.yaml
```

And then deployed those manifests. Something like this:

```console
# build the manifests into foundation folder structure
while read -r overlay_dir; do
    cluster_dir="${overlay_dir%/*}"
    cluster="${cluster_dir##*/}"
    foundation_dir="${cluster_dir%/*}"
    foundation="${foundation_dir##*/}"
    foundation_cluster="${foundation}-${cluster}"
    foundations["manifests/$foundation/$cluster"]="${foundation_cluster}"
    mkdir -p "manifests/$foundation/$cluster"
    echo -e "Writing manifests from $cluster_dir to manifests/$foundation/$cluster/allinone.yaml"
    kubectl kustomize --enable-helm --helm-command helm "$cluster_dir" > "manifests/$foundation/$cluster/allinone.yaml"
done < <(find overlays/foundations -depth 3)

for f in "${!foundations[@]}"; do
  kubectl apply -f "$f/allinone.yaml"
done
```

### Build K8s Resource Manifests for dc01-fd01

Perhaps you want to validate your configurations. If you want to render all the KRM files from a foundation before applying them. Then we can run some tests to validate things like: we have all the correct labels, images are overlayed properly, etc.

```console
mkdir -p manifests/foundations/dc01-fd01/cluster01
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc01-fd01/cluster01 > manifests/foundations/dc01-fd01/cluster01/allinone.yaml
```

```console
mkdir -p manifests/foundations/dc01-fd01/cluster02
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc01-fd01/cluster02 > manifests/foundations/dc01-fd01/cluster02/allinone.yaml
```

### Build K8s Resource Manifests for dc01-fd02

```console
mkdir -p manifests/foundations/dc01-fd02/cluster01
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc01-fd02/cluster01 > manifests/foundations/dc01-fd02/cluster01/allinone.yaml
```

```console
mkdir -p manifests/foundations/dc01-fd02/cluster02
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc01-fd02/cluster02 > manifests/foundations/dc01-fd02/cluster02/allinone.yaml
```

### Build K8s Resource Manifests for dc02-fd01

```console
mkdir -p manifests/foundations/dc02-fd01/cluster01
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc02-fd01/cluster01 > manifests/foundations/dc02-fd01/cluster01/allinone.yaml
```

```console
mkdir -p manifests/foundations/dc02-fd01/cluster02
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc02-fd01/cluster02 > manifests/foundations/dc02-fd01/cluster02/allinone.yaml
```

### Build K8s Resource Manifests for dc02-fd02

```console
mkdir -p manifests/foundations/dc02-fd02/cluster01
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc02-fd02/cluster01 > manifests/foundations/dc02-fd02/cluster01/allinone.yaml
```

```console
mkdir -p manifests/foundations/dc02-fd02/cluster02
kubectl kustomize --enable-helm --helm-command helm overlays/foundations/dc02-fd02/cluster02 > manifests/foundations/dc02-fd02/cluster02/allinone.yaml
```

## Releases

We can cut a release and check in those manifests as a simplified release process.

```console
./scripts/release.sh v1.0.1
```
