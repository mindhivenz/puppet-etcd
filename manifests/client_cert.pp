class etcd::client_cert {

  include etcd

  $key_file = "$etcd::conf_dir/client-key.pem"
  $cert_file = "$etcd::conf_dir/client.pem"

  etcd::cert { 'client':
    key_file           => $key_file,
    cert_file          => $cert_file,
    extended_key_usage => ['clientAuth'],
  }

}
