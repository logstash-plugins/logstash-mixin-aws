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
                  if @role_arn && @role_session_name && @access_key_id && @secret_access_key
                    #assume_role providing all IAM for cross account in conf
                    Aws::AssumeRoleCredentials.new(
                      :client => Aws::STS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key.value, region: @region, http_proxy: @proxy_uri),
                      :role_arn => @role_arn,
                      :role_session_name => @role_session_name,
                      :external_id => @external_id)
                  elsif @role_arn && @role_session_name
                     #assume_role providing only ARN in conf and using AWS credential as per SDK search order
                     Aws::AssumeRoleCredentials.new(
                      :client => Aws::STS::Client.new( region: @region),
                      :role_arn => @role_arn,
                      :role_session_name => @role_session_name,
                      :external_id => @external_id)
                  elsif @access_key_id && @secret_access_key
                    #straight IAM from conf file
                    credentials_opts = {
                      :access_key_id => @access_key_id,
                      :secret_access_key => @secret_access_key.value
                      }
                    if @session_token
                      credentials_opts[:session_token] = @session_token.value 
                    end
                    Aws::Credentials.new(credentials_opts[:access_key_id],
                                        credentials_opts[:secret_access_key],
                                        credentials_opts[:session_token])
                  elsif @aws_credentials_file
                    #load IAM details from file
                    credentials_opts = YAML.load_file(@aws_credentials_file)
                    Aws::Credentials.new(credentials_opts[:access_key_id],
                                        credentials_opts[:secret_access_key],
                                        credentials_opts[:session_token])
                  end
                  
                end
  end
 
end
