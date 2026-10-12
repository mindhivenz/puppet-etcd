# frozen_string_literal: true

require 'spec_helper'

describe 'etcd' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { version: '3.5.0' } }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_user('etcd').with(ensure: 'present', gid: 'etcd') }
        it { is_expected.to contain_group('etcd').with_ensure('present') }
        it { is_expected.to contain_file('/etc/etcd').with(ensure: 'directory', owner: 'etcd', group: 'etcd', mode: '0755') }
      end

      context 'with a custom user, group and conf_dir' do
        let(:params) { super().merge(user: 'kv', group: 'kvgroup', conf_dir: '/opt/etcd/conf') }

        it { is_expected.to contain_user('kv').with_gid('kvgroup') }
        it { is_expected.to contain_group('kvgroup') }
        it { is_expected.to contain_file('/opt/etcd/conf').with(owner: 'kv', group: 'kvgroup') }
      end

      context 'without a version' do
        let(:params) { {} }

        it { is_expected.to compile.and_raise_error(%r{expects a value for parameter 'version'}) }
      end
    end
  end
end
