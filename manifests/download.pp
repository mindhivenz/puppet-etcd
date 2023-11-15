class etcd::download {

  include etcd

  $arch = $facts[os][architecture] ? {
    aarch64 => arm64,
    default => $facts[os][architecture],
  }
  $id = "etcd-v$etcd::version-linux-$arch"
  $download_filename = "$id.tar.gz"
  $extract_path = "/root/$id"

  archive { "/tmp/$download_filename":
    user         => 'root',
    group        => 'root',
    source       => "https://github.com/etcd-io/etcd/releases/download/v$etcd::version/$download_filename",
    extract      => true,
    extract_path => '/root',
    creates      => "$extract_path/etcd",
  }

}
