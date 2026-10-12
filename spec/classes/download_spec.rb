# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::download' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) { "class { etcd: version => '3.5.0' }" }
      let(:architecture) { 'amd64' }
      let(:facts) { os_facts.merge(os: os_facts[:os].merge(architecture: architecture)) }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_archive('/tmp/etcd-v3.5.0-linux-amd64.tar.gz').with(
          user: 'root',
          group: 'root',
          source: 'https://github.com/etcd-io/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-amd64.tar.gz',
          extract: true,
          extract_path: '/root',
          creates: '/root/etcd-v3.5.0-linux-amd64/etcd',
        )
      end

      context 'on aarch64' do
        let(:architecture) { 'aarch64' }

        it do
          is_expected.to contain_archive('/tmp/etcd-v3.5.0-linux-arm64.tar.gz').with(
            source: 'https://github.com/etcd-io/etcd/releases/download/v3.5.0/etcd-v3.5.0-linux-arm64.tar.gz',
            creates: '/root/etcd-v3.5.0-linux-arm64/etcd',
          )
        end
      end

      context 'on arm64' do
        let(:architecture) { 'arm64' }

        it { is_expected.to contain_archive('/tmp/etcd-v3.5.0-linux-arm64.tar.gz') }
      end
    end
  end
end
