# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:os_facts) { os_facts }
      let(:params) { { token: 'some-token' } }

      include_context 'with etcd node'

      context 'when present' do
        it { is_expected.to compile.with_all_deps }

        %w[etcd::download etcd::ca etcd::server_cert etcd::client].each do |dependency|
          it { is_expected.to contain_class(dependency).that_comes_before('Class[etcd::server]') }
        end

        it do
          is_expected.to contain_file('/usr/local/bin/etcd').with(
            ensure: 'file',
            source: '/root/etcd-v3.5.0-linux-amd64/etcd',
            owner: 'root',
            group: 'root',
            mode: '0755',
            replace: false,
          )
        end

        it do
          is_expected.to contain_file('/var/lib/etcd')
            .with(ensure: 'directory', owner: 'etcd', group: 'etcd', mode: '0700')
            .that_requires('File[/etc/etcd]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/etcd.conf')
            .with(ensure: 'file', owner: 'etcd', group: 'etcd', mode: '0644', replace: false)
            .that_requires('File[/var/lib/etcd]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/etcd.conf').with_content(<<~CONF)

            ETCD_NAME="node1"
            ETCD_INITIAL_CLUSTER_STATE="new"
            ETCD_DATA_DIR="/var/lib/etcd"
            ETCD_INITIAL_CLUSTER_TOKEN="some-token"

            ETCD_INITIAL_CLUSTER="node1=https://node1:2380"

            ETCD_LISTEN_PEER_URLS="https://10.0.0.1:2380"
            ETCD_LISTEN_CLIENT_URLS="https://10.0.0.1:2379"

            ETCD_INITIAL_ADVERTISE_PEER_URLS="https://node1:2380"
            ETCD_ADVERTISE_CLIENT_URLS="https://node1:2379"

            ETCD_TRUSTED_CA_FILE="/etc/etcd/ca.pem"
            ETCD_CERT_FILE="/etc/etcd/server.pem"
            ETCD_KEY_FILE="/etc/etcd/server-key.pem"

            ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ca.pem"
            ETCD_PEER_CERT_FILE="/etc/etcd/server.pem"
            ETCD_PEER_KEY_FILE="/etc/etcd/server-key.pem"
          CONF
        end

        it do
          is_expected.to contain_systemd__unit_file('etcd.service')
            .with(enable: true, active: true)
            .that_subscribes_to(['File[/usr/local/bin/etcd]', 'File[/etc/etcd/etcd.conf]'])
        end

        it { is_expected.to contain_service('etcd.service').with(ensure: true, enable: true) }

        it do
          is_expected.to contain_systemd__unit_file('etcd.service').with_content(<<~UNIT)
            [Unit]
            Description=etcd key-value store
            Documentation=https://github.com/etcd-io/etcd
            After=network-online.target time-sync.target
            Wants=network-online.target time-sync.target

            [Service]
            User=etcd
            Type=notify
            EnvironmentFile=/etc/etcd/etcd.conf
            ExecStart=/usr/local/bin/etcd
            Restart=always
            RestartSec=10s
            LimitNOFILE=40000

            [Install]
            WantedBy=multi-user.target
          UNIT
        end

        {
          'etcd-env-cacert' => 'export ETCDCTL_CACERT=/etc/etcd/ca.pem',
          'etcd-env-cert' => 'export ETCDCTL_CERT=/etc/etcd/server.pem',
          'etcd-env-key' => 'export ETCDCTL_KEY=/etc/etcd/server-key.pem',
          'etcd-env-endpoints' => 'export ETCDCTL_ENDPOINTS=https://node1:2379',
        }.each do |title, line|
          it do
            is_expected.to contain_file_line(title).with(
              path: '/root/.bashrc',
              line: line,
              match: "^#{line.split('=').first}=",
            )
          end
        end

        it { is_expected.not_to contain_exec('etcd-join-existing-cluster') }
      end

      context 'when latest' do
        let(:params) { super().merge(ensure: 'latest') }

        it { is_expected.to contain_file('/usr/local/bin/etcd').with_replace(true) }
        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_replace(true) }
      end

      context 'with custom ports, directories and user' do
        let(:params) { super().merge(data_dir: '/srv/etcd', peer_port: 12_380) }
        let(:etcd_params) do
          { conf_dir: '/opt/etcd/conf', bin_dir: '/opt/etcd/bin', user: 'kv', group: 'kvgroup', client_port: 12_379 }
        end

        it { is_expected.to contain_file('/opt/etcd/bin/etcd') }
        it { is_expected.to contain_file('/srv/etcd').with(owner: 'kv', group: 'kvgroup') }
        it { is_expected.to contain_file('/opt/etcd/conf/etcd.conf').with(owner: 'kv', group: 'kvgroup') }
        it { is_expected.to contain_file('/opt/etcd/conf/etcd.conf').with_content(%r{^ETCD_DATA_DIR="/srv/etcd"$}) }
        it { is_expected.to contain_file('/opt/etcd/conf/etcd.conf').with_content(%r{^ETCD_INITIAL_CLUSTER="node1=https://node1:12380"$}) }
        it { is_expected.to contain_file('/opt/etcd/conf/etcd.conf').with_content(%r{^ETCD_LISTEN_PEER_URLS="https://10.0.0.1:12380"$}) }
        it { is_expected.to contain_file('/opt/etcd/conf/etcd.conf').with_content(%r{^ETCD_ADVERTISE_CLIENT_URLS="https://node1:12379"$}) }
        it { is_expected.to contain_file('/opt/etcd/conf/etcd.conf').with_content(%r{^ETCD_TRUSTED_CA_FILE="/opt/etcd/conf/ca.pem"$}) }
        it { is_expected.to contain_systemd__unit_file('etcd.service').with_content(%r{^User=kv$}) }
        it { is_expected.to contain_systemd__unit_file('etcd.service').with_content(%r{^ExecStart=/opt/etcd/bin/etcd$}) }
        it { is_expected.to contain_systemd__unit_file('etcd.service').with_content(%r{^EnvironmentFile=/opt/etcd/conf/etcd.conf$}) }
        it { is_expected.to contain_file_line('etcd-env-endpoints').with_line('export ETCDCTL_ENDPOINTS=https://node1:12379') }
      end

      context 'when an initial member of a multi-node cluster' do
        let(:etcd_params) { { initial_member_hostnames: %w[node0 node1], added_member_hostnames: ['node2'] } }

        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_content(%r{^ETCD_INITIAL_CLUSTER_STATE="new"$}) }

        it do
          is_expected.to contain_file('/etc/etcd/etcd.conf')
            .with_content(%r{^ETCD_INITIAL_CLUSTER="node0=https://node0:2380,node1=https://node1:2380,node2=https://node2:2380"$})
        end

        it do
          is_expected.to contain_file_line('etcd-env-endpoints')
            .with_line('export ETCDCTL_ENDPOINTS=https://node0:2379,https://node1:2379,https://node2:2379')
        end

        it { is_expected.not_to contain_exec('etcd-join-existing-cluster') }
      end

      context 'when added to an existing cluster' do
        let(:etcd_params) { { initial_member_hostnames: ['node0'], added_member_hostnames: ['node1'] } }

        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_content(%r{^ETCD_INITIAL_CLUSTER_STATE="existing"$}) }
        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_content(%r{^ETCD_INITIAL_CLUSTER="node0=https://node0:2380,node1=https://node1:2380"$}) }

        it do
          is_expected.to contain_exec('etcd-join-existing-cluster')
            .with(
              command: '/usr/local/bin/etcdctl member add node1 --peer-urls=https://node1:2380 --cacert=/etc/etcd/ca.pem ' \
                       '--cert=/etc/etcd/server.pem --key=/etc/etcd/server-key.pem ' \
                       '--endpoints=https://node0:2379,https://node1:2379',
              creates: '/var/lib/etcd/member',
            )
            .that_requires('File[/var/lib/etcd]')
            .that_comes_before('Systemd::Unit_file[etcd.service]')
        end
      end

      context 'with a local hostname override' do
        let(:etcd_params) { { local_hostname: 'etcd-a' } }

        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_content(%r{^ETCD_NAME="etcd-a"$}) }
        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_content(%r{^ETCD_INITIAL_CLUSTER="etcd-a=https://etcd-a:2380"$}) }
      end

      context 'when absent' do
        let(:params) { super().merge(ensure: 'absent') }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/usr/local/bin/etcd').with_ensure('absent').that_requires('Systemd::Unit_file[etcd.service]') }
        it { is_expected.to contain_file('/etc/etcd/etcd.conf').with_ensure('absent').that_requires('Systemd::Unit_file[etcd.service]') }
        it { is_expected.to contain_systemd__unit_file('etcd.service').with(ensure: 'absent', enable: false, active: false) }
        it { is_expected.to contain_service('etcd.service').with(ensure: false, enable: false) }
        it { is_expected.to contain_file('/var/lib/etcd').with(ensure: 'absent', force: true).that_requires('Systemd::Unit_file[etcd.service]') }
        it { is_expected.not_to contain_class('etcd::download') }
        it { is_expected.not_to contain_class('etcd::server_cert') }

        %w[CACERT CERT KEY ENDPOINTS].each do |variable|
          it do
            is_expected.to contain_file_line("etcd-env-#{variable.downcase}").with(
              ensure: 'absent',
              path: '/root/.bashrc',
              match: "^export ETCDCTL_#{variable}=",
              match_for_absence: true,
            )
          end
        end
      end
    end
  end
end
