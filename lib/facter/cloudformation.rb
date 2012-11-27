require 'facter'
require 'aws-sdk'
require 'yaml'

config = YAML.load_file("/etc/puppet/aws.yaml")
AWS.config(:credential_provider => AWS::Core::CredentialProviders::EC2Provider.new)
cfn = AWS::CloudFormation.new

cfn.stacks[config["stack_name"]].resources[config["resource_id"]].metadata.each do |namespace, items|
  items.each do |key, value|
    Facter.add("cfn_%s_%s" % [namespace, key]) do
      setcode do
        value
      end
    end
  end
end

