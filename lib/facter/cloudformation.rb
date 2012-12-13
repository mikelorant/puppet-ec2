require 'facter'
require 'aws-sdk'
require 'yaml'
require 'open-uri'

EC2_METADATA_URL="http://169.254.169.254/latest/meta-data/"
begin
  aws_region = open(EC2_METADATA_URL + "/placement/availability-zone").read[/([a-z]{2}-(?:west|east|north|south)-\d)[a-z]/,1]
  cfn = AWS::CloudFormation.new(:cloud_formation_endpoint => "cloudformation.#{region}.amazonaws.com")

  ec2_conn = AWS::EC2.new.regions[aws_region]
  instance_tags = ec2_conn.instances[instance_id].tags
  stack_name = instance_tags["aws:cloudformation:stack-name"]
  resource_id = instance_tags["aws:cloudformation:logical-id"]
  stack = cfn.stacks[stack_name]
  resource = stack.resources[resource_id]

  Facter.add("cfn_stack_name") do
    setcode do
      stack_name
    end
  end
  Facter.add("cfn_stack_id") do
    setcode do
      stack_id
    end
  end
  Facter.add("cfn_logical_resource_id") do
    setcode do
      resource.logical_resource_id
    end
  end
  Facter.add("cfn_physical_resource_id") do
    setcode do
      resource.physical_resource_id
    end
  end
  JSON.load(resource.metadata).each do |namespace, items|
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
