# Multi-cluster, Multi-tenant TKGi Kustomize Example

This repository shows an example of how to use Kustomize's bases and overlays to maintain manifests for an application that requires one instance of the application to be deployed per tenant and per environment.

Bases are configurations that inherit nothing. Overlays are configurations that inherit from somewhere. Overlays can inherit from bases or from other overlays.

## Example

```console
mkdir -p output/tenants/namespace-2/nonprod
kustomize build overlays/tenants/namespace-2/nonprod > output/tenants/namespace-2/nonprod/allinone.yaml
```

