# Changelog

## Release 2.2.0

### Bug fixes

- `etcd::server` with `ensure => absent` now stops and disables `etcd.service` before removing the
  binary, configuration, unit file and data directory
- `etcd::server` with `ensure => absent` now removes the `ETCDCTL_*` lines from root's `.bashrc`
- The `etcd.service` unit runs as `etcd::user` instead of always as `etcd`

### Other changes

- Declare the `puppet/archive` dependency, which `etcd::download` already used
- Require Puppet `>= 7.0.0 < 9.0.0` and support Ubuntu 20.04, 22.04 and 24.04
- Converted from PDK to jig, with VoxBox CI and full spec coverage

## Release 2.1.2

### Other changes

- Allow `puppet/systemd` up to `< 9.0.0`

## Release 2.1.1

### Bug Fix

- Apply .bashrc in correct place

## Release 2.1.0

### New features

- Set environment vars for `etcdctl` in `.bashrc`

## Release 2.0.1

### Bug fix

- `ETCD_INITIAL_CLUSTER` needs to include `etcd::added_member_hostnames`
  
## Release 2.0.0
  
### Breaking changes

- Rename parameter `etcd::member_hostnames` to `etcd::initial_member_hostnames`
  - The `etcd` module still exposes `etcd::member_hostnames` which is the combination of
    `etcd::initial_member_hostnames` and `etcd::added_member_hostnames`

### New features

- After initial cluster creation, new members can be added by listing them in
  `etcd::added_member_hostnames` – *NOTE: manually remove any removed nodes before adding* 

## Release 1.0.0

- Initial release
