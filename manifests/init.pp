class etcd (
  String $version, # e.g. 3.5.0, user forced to specify
  String $local_hostname                  = $facts[networking][hostname],
  # Changing this will not add or remove members from cluster after initialization
  Array[String] $initial_member_hostnames = [$local_hostname],
  Array[String] $added_member_hostnames   = [],
  Stdlib::Absolutepath $conf_dir          = '/etc/etcd',
  Stdlib::Absolutepath $bin_dir           = '/usr/local/bin',
  String $user                            = 'etcd',
  String $group                           = 'etcd',
  Integer $client_port                    = 2379,
) {

  $member_hostnames = $initial_member_hostnames + $added_member_hostnames
  $cluster_endpoint = join($member_hostnames.map | $name | { "https://$name:$client_port" }, ',')
  $is_member = $local_hostname in $member_hostnames

  user { $user:
    ensure => present,
    gid    => $group,
  }
  group { $group:
    ensure => present,
  }

  file { $conf_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

}
