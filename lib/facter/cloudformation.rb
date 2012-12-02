require 'facter'
require 'aws-sdk'
require 'yaml'
require 'net/http'

EC2_METADATA_URL="http://169.254.169.254/latest/meta-data/"
begin
  config = YAML.load_file("/etc/puppet/aws.yaml")

  region = Net::HTTP.get(URI.parse(EC2_METADATA_URL + "placement/availability-zone")).sub(/^([a-z]{2}-[a-z]+-\d)[a-z]/, '\1')
  AWS.config(:credential_provider => AWS::Core::CredentialProviders::EC2Provider.new, 
            :cloud_formation_endpoint => "cloudformation.#{region}.amazonaws.com")
  cfn = AWS::CloudFormation.new

  JSON.load(cfn.stacks[config["stack_name"]].resources[config["resource_id"]].metadata).each do |namespace, items|
    items.each do |key, value|
      Facter.add("cfn_%s_%s" % [namespace, key]) do
        setcode do
          value
        end
      end
    end
  end

rescue Exception => e
end
