# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin_mixins/aws_config"
require 'aws-sdk'

class DummyInputAwsConfig < LogStash::Inputs::Base
  include LogStash::PluginMixins::AwsConfig


  def aws_service_endpoint(region, s3_host)
    { :dummy_input_aws_config_region => "#{region}.#{s3_host}" }
  end
end

describe LogStash::PluginMixins::AwsConfig do

  let(:settings) { {} }

  subject { DummyInputAwsConfig.new(settings).aws_options_hash }

  describe 'config credential' do

    context 'in credential file' do
      let(:settings) { { 'aws_credentials_file' => File.join(File.dirname(__FILE__), '..', 'fixtures/aws_credentials_file_sample_test.yml') } }

      it 'should support reading configuration from a yaml file' do
        subject[:access_key_id].should == '1234'
        subject[:secret_access_key].should == 'secret'
      end
    end

    context 'inline' do
      context 'temporary credential' do
        let(:settings) { { 'access_key_id' => '1234', 'secret_access_key' => 'secret', 'session_token' => 'session_token' } }

        it "should support passing as key, value, and session_token" do
          subject[:access_key_id].should == settings['access_key_id']
          subject[:secret_access_key].should == settings['secret_access_key']
          subject[:session_token].should == settings['session_token']
        end
      end

      context 'normal credential' do
        let(:settings) { { 'access_key_id' => '1234',  'secret_access_key' => 'secret' } }

        it 'should support passing credentials as key, value' do
          subject[:access_key_id].should == settings['access_key_id']
          subject[:secret_access_key].should == settings['secret_access_key']
        end
      end
    end

  end

  describe 'config region' do

    context 'region provided' do
      let(:settings) { { 'access_key_id' => '1234',  'secret_access_key' => 'secret', 'region' => 'us-west-2' } }

      it 'should use provided region to generate the endpoint configuration' do
        subject[:dummy_input_aws_config_region].should == "us-west-2.amazonaws.com"
      end
    end

    context "region not provided" do
      let(:settings) { { 'access_key_id' => '1234',  'secret_access_key' => 'secret'} }

      it 'should use default region to generate the endpoint configuration' do
        subject[:dummy_input_aws_config_region].should == "us-east-1.amazonaws.com"
      end
    end

    context 'host provided' do
      let(:settings) { { 'access_key_id' => '1234',  'secret_access_key' => 'secret', 's3_host' => 's3.mycustom.domain' } }
      it 'should use provided region to generate the endpoint configuration' do
        subject[:dummy_input_aws_config_region].should == "s3.mycustom.domain"
      end
    end

    context "host not provided" do
      let(:settings) { { 'access_key_id' => '1234',  'secret_access_key' => 'secret'} }

      it 'should use default region to generate the endpoint configuration' do
        subject[:dummy_input_aws_config_region].should == "us-east-1.amazonaws.com"
      end
    end
  end

  context 'when we arent providing credentials' do
    let(:settings) { {} }
    it 'should always return a hash' do
      expect(subject).to eq({ :use_ssl => true, :dummy_input_aws_config_region => "us-east-1.amazonaws.com" })
    end
  end
end
