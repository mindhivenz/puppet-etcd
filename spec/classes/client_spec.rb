# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::client' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:os_facts) { os_facts }

      include_context 'with etcd node'

      context 'when present' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('etcd::client_cert') }

        it do
          is_expected.to contain_file('/usr/local/bin/etcdctl')
            .with(
              ensure: 'file',
              source: '/root/etcd-v3.5.0-linux-amd64/etcdctl',
              owner: 'root',
              group: 'root',
              mode: '0755',
              replace: false,
            )
            .that_requires('Class[etcd::download]')
        end
      end

      context 'when latest' do
        let(:params) { { ensure: 'latest' } }

        it { is_expected.to contain_file('/usr/local/bin/etcdctl').with_replace(true) }
      end

      context 'with a custom bin_dir' do
        let(:etcd_params) { { bin_dir: '/opt/etcd/bin' } }

        it { is_expected.to contain_file('/opt/etcd/bin/etcdctl') }
      end

      context 'when absent' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/usr/local/bin/etcdctl').with_ensure('absent') }
        it { is_expected.not_to contain_class('etcd::download') }
        it { is_expected.not_to contain_class('etcd::client_cert') }
      end
    end
  end
end
