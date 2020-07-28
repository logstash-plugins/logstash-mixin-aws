# encoding: utf-8
require "logstash/plugin_mixins/aws_config/generic"

module LogStash::PluginMixins::AwsConfig::V2
  def self.included(base)
    base.extend(self)
    base.send(:include, LogStash::PluginMixins::AwsConfig::Generic)
  end

  public
  def aws_options_hash
    opts = {}

    if @access_key_id.is_a?(NilClass) ^ @secret_access_key.is_a?(NilClass)
      @logger.warn("Likely config error: Only one of access_key_id or secret_access_key was provided but not both.")
    end

    opts[:credentials] = credentials if credentials

    opts[:http_proxy] = @proxy_uri if @proxy_uri

    if self.respond_to?(:aws_service_endpoint)
      # used by CloudWatch to basically do the same as bellow (returns { region: region })
      opts.merge!(self.aws_service_endpoint(@region))
    else
      # NOTE: setting :region works with the aws sdk (resolves correct endpoint)
      opts[:region] = @region
    end

    if !@endpoint.is_a?(NilClass)
      opts[:endpoint] = @endpoint
    end

    return opts
  end

  private
  def credentials
    @creds ||= begin
                  if @session_token
                    credentials_opts[:session_token] = @session_token.value 
                  end
                  if @role_arn && @external_id && @proxy_uri && @access_key_id && @secret_access_key
                   Aws::AssumeRoleCredentials.new(
                    :client => Aws::STS::Client.new(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key, :region => @region, :http_proxy => @proxy_uri),
                    :role_arn => @role_arn,
                    :role_session_name => @role_session_name,
                    :external_id => @external_id)
                  elsif @role_arn && @external_id && @access_key_id && @secret_access_key
                   Aws::AssumeRoleCredentials.new(
                    :client => Aws::STS::Client.new(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key, :region => @region),
                    :role_arn => @role_arn,
                    :role_session_name => @role_session_name,
                    :external_id => @external_id)
                   elsif @role_arn && @proxy_uri
                    Aws::AssumeRoleCredentials.new(
                      :client => Aws::STS::Client.new(:region => @region),
                      :role_arn => @role_arn,
                      :role_session_name => @role_session_name)
                    elsif @role_arn
                      Aws::AssumeRoleCredentials.new(
                        :client => Aws::STS::Client.new(:region => @region),
                        :role_arn => @role_arn,
                        :role_session_name => @role_session_name)
                    elsif @access_key_id && @secret_access_key
                      Aws::Credentials.new(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key, :session_token => @session_token)
                    elsif @aws_credentials_file
                      credentials_opts = YAML.load_file(@aws_credentials_file)
                      Aws::Credentials.new(:access_key_id => @access_key_id, :secret_access_key => @secret_access_key, :session_token => @session_token)
                    end
                end
  end

  
end
