require 'facter'
require 'aws-sdk-core'
require 'yaml'
require 'open-uri'

EC2_METADATA_URL="http://169.254.169.254/latest/meta-data/" unless Module.const_defined?(:EC2_METADATA_URL)
begin
  region = open(EC2_METADATA_URL + "placement/availability-zone").read.chop
  instance_id = open(EC2_METADATA_URL + "/instance-id").read

  cfn = Aws::CloudFormation::Client.new(:region => region)
  ec2 = Aws::EC2::Client.new(:region => region)

  instance_tags = ec2.describe_instances(instance_ids: [instance_id]).reservations.first.instances.first.tags
  stack_name = instance_tags.select { |tag| tag.key == 'aws:cloudformation:stack-name' }.first.value
  stack_id = instance_tags.select { |tag| tag.key == 'aws:cloudformation:stack-id' }.first.value
  resource_id = instance_tags.select { |tag| tag.key == 'aws:cloudformation:logical-id' }.first.value
  stack = cfn.describe_stack_resource(stack_name: stack_name, logical_resource_id: resource_id)
  resource = stack.stack_resource_detail
  stack_info = cfn.describe_stacks({ stack_name: stack_name }).stacks.first

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

  if resource.metadata
    JSON.load(resource.metadata).each do |namespace, items|
      items.each do |key, value|
        Facter.add("cfn_%s_%s" % [namespace, key]) do
          setcode do
            value
          end
        end
      end
    end
  end

  stack_info.parameters.each do |param|
    Facter.add("cfn_stack_param_%s" % param.parameter_key.downcase) do
      setcode do
        param.parameter_value
      end
    end
  end

rescue Exception => e
end
