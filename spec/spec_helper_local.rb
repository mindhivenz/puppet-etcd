# frozen_string_literal: true

def puppet_params(params)
  params.map { |name, value| "#{name} => #{value.inspect}," }.join("\n")
end

shared_context 'with etcd node' do
  let(:etcd_params) { {} }
  let(:facts) do
    os_facts.merge(networking: os_facts[:networking].merge(hostname: 'node1', fqdn: 'node1.example.com', ip: '10.0.0.1'))
  end
  let(:pre_condition) do
    <<~EOS
      class { etcd:
        version => '3.5.0',
        #{puppet_params(etcd_params)}
      }
      class { etcd::ca:
        ca_cert_content   => 'some-cert',
        ca_key_content    => 'some-key',
        ca_key_passphrase => 'some-passphrase',
      }
    EOS
  end
end
