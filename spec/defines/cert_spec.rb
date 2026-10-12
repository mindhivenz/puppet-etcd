# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::cert' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:os_facts) { os_facts }
      let(:title) { 'peer' }
      let(:params) do
        {
          cert_file: '/etc/etcd/peer.pem',
          key_file: '/etc/etcd/peer-key.pem',
          extended_key_usage: %w[clientAuth serverAuth],
        }
      end

      include_context 'with etcd node'

      context 'without subject alternate names' do
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_openssl_genpkey('/etc/etcd/peer-key.pem')
            .with(algorithm: 'RSA', bits: '2048')
            .that_requires('File[/etc/etcd]')
        end

        it do
          is_expected.to contain_openssl__csr('/etc/etcd/ca/peer.csr')
            .with(
              common_name: 'node1.example.com',
              config: '/etc/etcd/ca/peer-csr.cnf',
              key_file: '/etc/etcd/peer-key.pem',
              subject_alternate_names_dns: [],
              subject_alternate_names_ip: [],
              key_usage: %w[digitalSignature keyEncipherment],
              extended_key_usage: %w[clientAuth serverAuth],
            )
            .that_requires(['Openssl_genpkey[/etc/etcd/peer-key.pem]', 'File[/etc/etcd/ca]'])
        end

        it do
          is_expected.to contain_openssl_signcsr('/etc/etcd/peer.pem')
            .with(
              csr: '/etc/etcd/ca/peer.csr',
              extfile: '/etc/etcd/ca/peer-csr.cnf',
              extensions: 'ca_ext',
              days: 18_250,
              ca_name: 'CA',
              ca_config: '/etc/etcd/ca/ca.cnf',
              password: 'some-passphrase',
            )
            .that_requires('Openssl::Csr[/etc/etcd/ca/peer.csr]')
            .that_subscribes_to('Class[etcd::ca]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/peer-key.pem')
            .with(ensure: 'file', owner: 'etcd', group: 'etcd', mode: '0640')
            .that_requires('Openssl_signcsr[/etc/etcd/peer.pem]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/peer.pem')
            .with(ensure: 'file', owner: 'etcd', group: 'etcd', mode: '0644')
            .that_requires('File[/etc/etcd/peer-key.pem]')
        end
      end

      context 'with subject alternate names' do
        let(:params) do
          super().merge(subject_alternate_names_dns: ['node1.example.com'], subject_alternate_names_ip: ['10.0.0.1'])
        end

        it do
          is_expected.to contain_openssl__csr('/etc/etcd/ca/peer.csr').with(
            subject_alternate_names_dns: ['node1.example.com'],
            subject_alternate_names_ip: ['10.0.0.1'],
          )
        end
      end
    end
  end
end
