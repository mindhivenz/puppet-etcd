# Changelog

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
