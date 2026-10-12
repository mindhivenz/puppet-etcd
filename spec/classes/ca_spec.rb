# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::ca' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { "class { etcd: version => '3.5.0' }" }
      let(:params) do
        { ca_cert_content: 'some-cert', ca_key_content: 'some-key', ca_key_passphrase: 'some-passphrase' }
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('openssl').with_cert_source_directory('/etc/puppetlabs/stm_openssl') }

        it do
          is_expected.to contain_file('/etc/etcd/ca.pem')
            .with(ensure: 'file', owner: 'root', group: 'root', mode: '0644', content: 'some-cert')
            .that_requires('File[/etc/etcd]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/ca')
            .with(ensure: 'directory', owner: 'root', group: 'root', mode: '0700')
            .that_requires('File[/etc/etcd/ca.pem]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/ca/index.txt')
            .with(ensure: 'file', owner: 'root', group: 'root', mode: '0644', content: nil)
            .that_requires('File[/etc/etcd/ca]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/ca/ca-key.pem')
            .with(ensure: 'file', owner: 'root', group: 'root', mode: '0600', content: 'some-key')
            .that_requires('File[/etc/etcd/ca/index.txt]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/ca/ca.cnf')
            .with(ensure: 'file', owner: 'root', group: 'root', mode: '0600')
            .that_requires('File[/etc/etcd/ca/ca-key.pem]')
        end

        it do
          is_expected.to contain_file('/etc/etcd/ca/ca.cnf').with_content(<<~CNF)

            [ CA ]
            certificate    = /etc/etcd/ca.pem
            private_key    = /etc/etcd/ca/ca-key.pem

            new_certs_dir  = /etc/etcd/ca
            database       = /etc/etcd/ca/index.txt
            serial         = /etc/etcd/ca/serial.txt
            default_md     = sha256
            policy         = policy_anything
            unique_subject = no

            [ policy_anything ]
            countryName             = optional
            stateOrProvinceName     = optional
            localityName            = optional
            organizationName        = optional
            organizationalUnitName  = optional
            commonName              = supplied
            emailAddress            = optional
          CNF
        end
      end

      context 'with a custom ca_name and conf_dir' do
        let(:pre_condition) { "class { etcd: version => '3.5.0', conf_dir => '/opt/etcd/conf' }" }
        let(:params) { super().merge(ca_name: 'etcd-ca') }

        it { is_expected.to contain_file('/opt/etcd/conf/ca.pem') }
        it { is_expected.to contain_file('/opt/etcd/conf/ca/ca.cnf').with_content(%r{^\[ etcd-ca \]$}) }
        it { is_expected.to contain_file('/opt/etcd/conf/ca/ca.cnf').with_content(%r{^database       = /opt/etcd/conf/ca/index.txt$}) }
      end
    end
  end
end
