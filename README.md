# etcd

Installs and configures an [etcd](https://etcd.io) cluster secured with TLS, and the `etcdctl` client.

## Description

The module:

* downloads the etcd release tarball for the node's architecture from GitHub and installs the `etcd` and `etcdctl` binaries
* manages a private CA on each node from a CA certificate and key you supply, and signs a server and a client certificate for the node with [stm/openssl](https://forge.puppet.com/modules/stm/openssl)
* configures etcd as a systemd service, with peer and client traffic over TLS
* sets `ETCDCTL_*` environment variables in root's `.bashrc`, so `etcdctl` works without extra flags
* can add members to an existing cluster

[mindhive/k3s](https://github.com/mindhivenz/puppet-k3s) uses it as the k3s datastore.

## Usage

Declare `etcd` and `etcd::ca` (in Hiera or as resource-like classes), then `etcd::server` on cluster members and `etcd::client` on nodes that only need `etcdctl`:

```puppet
class { 'etcd':
  version                  => '3.5.0',
  initial_member_hostnames => ['node0', 'node1', 'node2'],
}
class { 'etcd::ca':
  ca_cert_content   => $ca_cert,
  ca_key_content    => $ca_key,
  ca_key_passphrase => $ca_key_passphrase,
}
class { 'etcd::server':
  token => 'some-cluster-token',
}
```

### Adding members

`initial_member_hostnames` only takes effect when the cluster is first created. To add a node later, list it in `added_member_hostnames`. The new node then joins with `etcdctl member add`. Remove any departed members by hand before adding.

### Upgrading

With `ensure => present`, the installed binaries and `etcd.conf` are left as they are once they exist. Set `ensure => latest` on `etcd::server` or `etcd::client` to replace them after changing `version` or other settings.

### Removing

`ensure => absent` on `etcd::server` stops and disables the service, then removes the binary, configuration, unit file and data directory, and the `ETCDCTL_*` lines in root's `.bashrc`. On `etcd::client` it removes `etcdctl`.

## Limitations

Supports Ubuntu 20.04, 22.04 and 24.04 on amd64 and arm64, with Puppet 7 and 8. CI tests OpenVox 8 only.

## Development

The module is managed with [jig](https://github.com/voxpupuli/jig). Validation and unit tests run inside the [VoxBox](https://github.com/voxpupuli/container-voxbox) container, so the only host requirements are jig and Docker (or Podman).

### Setup

Install jig from its [releases](https://github.com/voxpupuli/jig/releases), then point its runner at the same VoxBox image CI uses (see `VOXBOX_IMAGE` in `.github/workflows/ci.yml`):

```shell
export JIG_RUNNER_TYPE=voxbox
export JIG_RUNNER_IMAGE=ghcr.io/voxpupuli/voxbox:10.1.0-openvox8.30.0@sha256:01bb8ce5e24d5b111934660f75e2786b4d7c7adcaa7518a564856d1d3041d10d
```

To make this permanent, put the equivalent `[runner]` section in your jig config file instead (see the [jig voxbox docs](https://github.com/voxpupuli/jig/blob/main/docs/voxbox.md)).

### Validate and test

```shell
jig validate     # syntax, puppet-lint and rubocop
jig test unit    # rspec-puppet unit tests
```

Run a single spec file by calling the container directly:

```shell
docker run --rm -v "$PWD:/repo" -e SPEC=spec/classes/server_spec.rb "$JIG_RUNNER_IMAGE" spec
```

### Build

```shell
jig build
```

The package is written to `pkg/`. Which files are packaged is controlled by the `[build]` section of `jig.toml`.
