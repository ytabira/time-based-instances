# coding: utf-8

require "./time_based_instances"

namespace :time_based_instances do

  desc "deploy"
  task :deploy do
    cloud_formation_template = TimeBasedInstances.new
    cloud_formation_template.stack.deploy(
      capabilities: ["CAPABILITY_IAM"],
    )
  end
  desc "update"
  task :update do
    cloud_formation_template = TimeBasedInstances.new
    cloud_formation_template.stack.update(
      capabilities: ["CAPABILITY_IAM"],
    )
  end
  desc "delete"
  task :delete do
    cloud_formation_template = TimeBasedInstances.new
    cloud_formation_template.stack.delete
  end
end
