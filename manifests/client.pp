class etcd::client (
  Enum[present, absent, latest] $ensure = 'present',
) {

  include etcd

  if $ensure != absent {

    include etcd::download
    include etcd::client_cert

    $upgrade = $ensure == latest

    Class[etcd::download]
    -> file { "$etcd::bin_dir/etcdctl":
      ensure  => file,
      source  => "$etcd::download::extract_path/etcdctl",
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      replace => $upgrade,
    }

  } else {

    file { "$etcd::bin_dir/etcdctl":
      ensure => absent,
    }

  }

}
