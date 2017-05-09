require 'spec_helper'
require 'jwtap/access_handler'

describe Jwtap::AccessHandler do
  let(:request) { double 'Nginx::Request', var: var }
  let(:var) { double 'Nginx::Var', jwtap_expiration_duration_seconds: nil, jwtap_cookie_name: nil }

  subject { described_class.new request }

  describe '#cookie_name' do
    it 'returns the default value' do
      expect(subject.send :cookie_name).to eq('jwt')
    end

    context 'given a configured value' do
      let(:var) { double 'Nginx::Var', jwtap_cookie_name: 'test-cookie-name' }

      it 'returns the configured value' do
        expect(subject.send :cookie_name).to eq('test-cookie-name')
      end
    end
  end

  describe '#expiration_duration_seconds' do
    it 'returns the default value' do
      expect(subject.send :expiration_duration_seconds).to eq(1800)
    end

    context 'given a configured value' do
      let(:var) { double 'Nginx::Var', jwtap_expiration_duration_seconds: 60 }

      it 'returns the configured value' do
        expect(subject.send :expiration_duration_seconds).to eq(60)
      end
    end
  end
end
