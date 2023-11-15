define etcd::cert (
  String $cert_file,
  String $key_file,
  Array[String] $extended_key_usage,
  Array[String] $subject_alternate_names_dns = [],
  Array[String] $subject_alternate_names_ip  = [],
) {

  include etcd
  include etcd::ca

  openssl_genpkey { $key_file:
    algorithm => 'RSA',
    bits      => '2048',
    require   => File[$etcd::conf_dir],
  }
  -> openssl::csr { "$etcd::ca::dir/$name.csr":
    common_name                 => $facts[networking][fqdn],
    config                      => "$etcd::ca::dir/$name-csr.cnf",
    key_file                    => $key_file,
    subject_alternate_names_dns => $subject_alternate_names_dns,
    subject_alternate_names_ip  => $subject_alternate_names_ip,
    key_usage                   => ['digitalSignature', 'keyEncipherment'],
    extended_key_usage          => $extended_key_usage,
    require                     => File[$etcd::ca::dir],
  }
  -> openssl_signcsr { $cert_file:
    csr        => "$etcd::ca::dir/$name.csr",
    extfile    => "$etcd::ca::dir/$name-csr.cnf",
    extensions => 'ca_ext',
    days       => 365 * 50,
    ca_name    => $etcd::ca::ca_name,
    ca_config  => $etcd::ca::config_file,
    password   => $etcd::ca::ca_key_passphrase,
    subscribe  => Class[etcd::ca],
  }
  -> file { $key_file:
    ensure => file,
    owner  => $etcd::user,
    group  => $etcd::group,
    mode   => '0640',
  }
  -> file { $cert_file:
    ensure => file,
    owner  => $etcd::user,
    group  => $etcd::group,
    mode   => '0644',
  }

}
