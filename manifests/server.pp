class etcd::server (
  String $token,
  Enum[present, absent, latest] $ensure = present,
  Stdlib::Absolutepath $data_dir        = '/var/lib/etcd',
  Integer $peer_port                    = 2380,
) {

  include etcd

  if $ensure != absent {

    require etcd::download
    require etcd::ca
    require etcd::server_cert

    $upgrade = $ensure == latest
    $cluster_state = if $etcd::local_hostname in $etcd::initial_member_hostnames { 'new' } else { 'existing' }

    file { "$etcd::bin_dir/etcd":
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
        token                    => $token,
        ip                       => $networking[ip],
        hostname                 => $etcd::local_hostname,
        cluster_state            => $cluster_state,
        cluster_member_hostnames => $etcd::member_hostnames,
        peer_port                => $peer_port,
        client_port              => $etcd::client_port,
        data_dir                 => $data_dir,
        ca_cert                  => $etcd::ca::cert_file,
        server_cert              => $etcd::server_cert::cert_file,
        server_key               => $etcd::server_cert::key_file,
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
      subscribe => [File["$etcd::bin_dir/etcd"], File["$etcd::conf_dir/etcd.conf"]],
    }

    if $etcd::local_hostname in $etcd::added_member_hostnames {
      require etcd::client

      exec { 'etcd-join-existing-cluster':
        command => join(
          [
            "$etcd::client::etcdctl_path member add $etcd::local_hostname",
            "--peer-urls=https://$etcd::local_hostname:$peer_port",
            "--cacert=$etcd::ca::cert_file",
            "--cert=$etcd::server_cert::cert_file",
            "--key=$etcd::server_cert::key_file",
            "--endpoints=$etcd::cluster_endpoint",
          ],
          ' '
        ),
        creates => "$data_dir/member",
        require => File[$data_dir],
        before  => Systemd::Unit_file['etcd.service'],
      }
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
