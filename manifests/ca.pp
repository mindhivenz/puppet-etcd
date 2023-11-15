class etcd::ca (
  String $ca_name = "CA",
  String $ca_cert_content,
  String $ca_key_content,
  String $ca_key_passphrase,
) {

  include etcd

  class { openssl:
    cert_source_directory => '/etc/puppetlabs/stm_openssl',
  }

  $dir = "$etcd::conf_dir/ca"
  $cert_file = "$etcd::conf_dir/ca.pem"
  $config_file = "$dir/ca.cnf"

  File[$etcd::conf_dir]
  -> file { $cert_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $ca_cert_content,
  }
  -> file { $dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
  -> file { "$dir/index.txt":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
  -> file { "$dir/ca-key.pem":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $ca_key_content,
  }
  -> file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => epp('etcd/ca.cnf.epp', {
      ca_name => $ca_name,
      db_dir  => $dir,
      db_file => "$dir/index.txt",
      ca_cert => $cert_file,
      ca_key  => "$dir/ca-key.pem",
    }),
  }

}
