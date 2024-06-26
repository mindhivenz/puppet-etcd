# frozen_string_literal: true

require 'spec_helper'

describe 'etcd::server' do
  on_supported_os.each do |os, os_facts|
    context "present on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'token' => 'some-token',
        }
      end
      let(:pre_condition) do
        <<~EOS
          class { etcd:
            version => '3.5.0',
          }
          class { etcd::ca:
            ca_cert_content   => 'some-cert',
            ca_key_content    => 'some-key',
            ca_key_passphrase => 'some-passphrase', 
          }
        EOS
      end

      it { is_expected.to compile.with_all_deps }
    end

    context "adding member on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'token' => 'some-token',
        }
      end
      let(:pre_condition) do
        <<~EOS
          class { etcd:
            version                  => '3.5.0',
            local_hostname           => 'some-host',
            initial_member_hostnames => ['other-host'],
            added_member_hostnames   => ['some-host'],
          }
          class { etcd::ca:
            ca_cert_content   => 'some-cert',
            ca_key_content    => 'some-key',
            ca_key_passphrase => 'some-passphrase', 
          }
        EOS
      end

      it { is_expected.to compile.with_all_deps }
    end

    context "absent on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'token' => 'some-token',
          'ensure' => 'absent',
        }
      end
      let(:pre_condition) do
        <<~EOS
          class { etcd:
            version => '3.5.0',
          }
          class { etcd::ca:
            ca_cert_content   => 'some-cert',
            ca_key_content    => 'some-key',
            ca_key_passphrase => 'some-passphrase', 
          }
        EOS
      end

      it { is_expected.to compile.with_all_deps }
    end
  end
end
