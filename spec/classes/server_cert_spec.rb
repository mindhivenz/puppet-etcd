# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::server_cert' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:os_facts) { os_facts }

      include_context 'with etcd node'

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_etcd__cert('server').with(
          key_file: '/etc/etcd/server-key.pem',
          cert_file: '/etc/etcd/server.pem',
          extended_key_usage: %w[clientAuth serverAuth],
          subject_alternate_names_dns: %w[node1.example.com node1],
          subject_alternate_names_ip: ['10.0.0.1'],
        )
      end
    end
  end
end
