require 'net/http'
require 'facter'
require 'json'

EC2_METADATA_URL="http://169.254.169.254/latest/meta-data/" unless Module.const_defined?(:EC2_METADATA_URL)
EC2_IAM_URL = EC2_METADATA_URL + "iam/security-credentials/" unless Module.const_defined?(:EC2_IAM_URL)
uri = URI.parse(EC2_IAM_URL)
http = Net::HTTP.new(uri.host, uri.port)
response = http.request(Net::HTTP::Get.new(uri.request_uri))

if response.code == "200"
  iam_roles_names = response.body.split
  iam_roles = iam_roles_names.reduce(Hash.new) do |h, role|
    h[role] = JSON.load(Net::HTTP.get(URI.parse(EC2_IAM_URL + role)))
    h
  end

  iam_roles.each do |role_name, role_credentials|
    role_credentials.each do |k, v|
      Facter.add("ec2_iam_role_%s_%s" % [role_name, k]) do
        setcode do
          v
        end
      end
    end
  end
  Facter.add("aws_access_key_id") do
    setcode do
      iam_roles.first[1]["AccessKeyId"]
    end
  end
  Facter.add("aws_secret_access_key") do
    setcode do
      iam_roles.first[1]["SecretAccessKey"]
    end
  end
  Facter.add("ec2_iam_roles") do
    setcode do
      iam_roles.keys.join(",")
    end
  end
end
