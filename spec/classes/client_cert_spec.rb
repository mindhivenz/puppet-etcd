# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::client_cert' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:os_facts) { os_facts }

      include_context 'with etcd node'

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_etcd__cert('client').with(
          key_file: '/etc/etcd/client-key.pem',
          cert_file: '/etc/etcd/client.pem',
          extended_key_usage: ['clientAuth'],
          subject_alternate_names_dns: [],
          subject_alternate_names_ip: [],
        )
      end
    end
  end
end
