class etcd::client (
  Enum[present, absent, latest] $ensure = present,
) {

  include etcd

  $etcdctl_path = "$etcd::bin_dir/etcdctl"

  if $ensure != absent {

    include etcd::download
    include etcd::client_cert

    $upgrade = $ensure == latest

    Class[etcd::download]
    -> file { $etcdctl_path:
      ensure  => file,
      source  => "$etcd::download::extract_path/etcdctl",
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      replace => $upgrade,
    }

  } else {

    file { $etcdctl_path:
      ensure => absent,
    }

  }

}
