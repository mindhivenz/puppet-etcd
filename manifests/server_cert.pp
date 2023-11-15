class etcd::server_cert {

  include etcd

  $key_file = "$etcd::conf_dir/server-key.pem"
  $cert_file = "$etcd::conf_dir/server.pem"

  etcd::cert { 'server':
    key_file                    => $key_file,
    cert_file                   => $cert_file,
    extended_key_usage          => ['clientAuth', 'serverAuth'],
    subject_alternate_names_dns => [$facts[networking][fqdn], $facts[networking][hostname]],
    subject_alternate_names_ip  => [$facts[networking][ip]],
  }

}
