class etcd::server (
  String $token,
  Enum[present, absent, latest] $ensure = present,
  Stdlib::Absolutepath $data_dir        = '/var/lib/etcd',
  Integer $peer_port                    = 2380,
) {

  include etcd

  if $ensure != absent {

    include etcd::download
    include etcd::ca
    include etcd::server_cert

    $upgrade = $ensure == latest

    Class[etcd::download]
    -> file { "$etcd::bin_dir/etcd":
      ensure  => file,
      source  => "$etcd::download::extract_path/etcd",
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      replace => $upgrade,
    }

    File[$etcd::conf_dir]  # In case data dir is under conf_dir
    -> file { $data_dir:
      ensure => directory,
      owner  => $etcd::user,
      group  => $etcd::group,
      mode   => '0700',
    }
    -> file { "$etcd::conf_dir/etcd.conf":
      ensure  => file,
      content => epp('etcd/etcd.conf.epp', {
        token            => $token,
        ip               => $networking[ip],
        hostname         => $etcd::local_hostname,
        member_hostnames => $etcd::member_hostnames,
        peer_port        => $peer_port,
        client_port      => $etcd::client_port,
        data_dir         => $data_dir,
        ca_cert          => $etcd::ca::cert_file,
        server_cert      => $etcd::server_cert::cert_file,
        server_key       => $etcd::server_cert::key_file,
      }),
      owner   => $etcd::user,
      group   => $etcd::group,
      mode    => '0644',
      replace => $upgrade,
    }

    systemd::unit_file { 'etcd.service':
      content   => epp('etcd/etcd.service.epp', {
        exe_file  => "$etcd::bin_dir/etcd",
        conf_file => "$etcd::conf_dir/etcd.conf",
      }),
      enable    => true,
      active    => true,
      subscribe => [Class[etcd::server_cert], File["$etcd::bin_dir/etcd"], File["$etcd::conf_dir/etcd.conf"]],
    }

  } else {

    file { "$etcd::bin_dir/etcd":
      ensure => absent,
    }
    file { "$etcd::conf_dir/etcd.conf":
      ensure => absent,
    }
    file { $data_dir:
      ensure => absent,
      force  => true,
    }
    systemd::unit_file { 'etcd.service':
      ensure => absent,
    }

  }

}
