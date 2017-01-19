# -*- coding: utf-8 -*-
require "humidifier"
require "active_support/core_ext/string/inflections"

ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'EC2'
end

class TimeBasedInstances

  attr_accessor :stack

  def initialize

    @stack = Humidifier::Stack.new(
      name: ENV["TIME_BASED_INSTANCES_STACK_NAME"],
      aws_template_format_version: "2010-09-09",
    )
    # 'aws_'から始まるプライベートメソッドをAWSリソースとみなしてスタックに登録する
    self.private_methods(false).grep(/^aws_/).each do |method_name|
      stack.add(method_name.to_s.sub(/^aws_/, "").camelize, send(method_name))
    end

  end

  private

  ##
  #=== EC2インスタンスを起動するLambda関数を呼び出すイベントルール
  def aws_stop_ec2_events_rule
    Humidifier::Events::Rule.new(
      schedule_expression: ENV["EC2_STOP_SCHEDULE_EXPRESSION"] || "cron(0 4 * * ? *)",
      role_arn: Humidifier.fn.get_att(["LambdaExecutionRole", "Arn"]),
      targets: [
        {
          arn: Humidifier.fn.get_att(["StopEC2Function", "Arn"]),
          id: "stop-ec2-function"
        }
      ]
    )
  end

  ##
  #=== EC2インスタンスを停止するLambda関数を呼び出すイベントルール
  def aws_start_ec2_events_rule
    Humidifier::Events::Rule.new(
      schedule_expression: ENV["EC2_START_SCHEDULE_EXPRESSION"] || "cron(0 1 ? * MON-FRI *)",
      role_arn: Humidifier.fn.get_att(["LambdaExecutionRole", "Arn"]),
      targets: [
        {
          arn: Humidifier.fn.get_att(["StartEC2Function", "Arn"]),
          id: "start-ec2-function"
        }
      ]
    )
  end

  ##
  #=== Lambda関数を実行するIAM Role
  def aws_lambda_execution_role
    Humidifier::IAM::Role.new(
      assume_role_policy_document: {
        Statement: [
          {
            Effect: "Allow",
            Principal: {
              Service: [
                "lambda.amazonaws.com",
                "events.amazonaws.com",
              ]
            },
            Action: [ "sts:AssumeRole" ]
          }
        ]
      },
      path: "/",
      policies: [
        {
          policy_name: "root",
          policy_document: {
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:PutLogEvents",
                  "ec2:StartInstances",
                  "ec2:StopInstances",

                ],
                Resource: [
                  "arn:aws:logs:*:*:*",
                  "arn:aws:ec2:*"
                ]
              }
            ]
          }
        }
      ]
    )
  end

  ##
  #=== EC2インスタンスを起動するLambda関数
  def aws_start_ec2_function
    Humidifier::Lambda::Function.new(
      handler: "index.handler",
      role: Humidifier.fn.get_att(["LambdaExecutionRole", "Arn"]),
      code: {
        zip_file: <<-EOS
const INSTANCE_IDS = [#{ENV["EC2_INSTANCE_IDS"]}];

var AWS = require('aws-sdk');
AWS.config.region = "#{ENV["AWS_REGION"]}";

function ec2Start(callback){
  var ec2 = new AWS.EC2();
  var params = {
    InstanceIds: INSTANCE_IDS
  };

  ec2.startInstances(params, function(err, data) {
    if (!!err) {
      console.log(err, err.stack);
    } else {
      console.log(data);
      callback();
    }
  });
}
exports.handler = function(event, context) {
  console.log('start');
  ec2Start(function() {
    context.done(null, 'Started Instance');
  });
};
    EOS
      },
      runtime: "nodejs4.3"
    )
  end

  ##
  #=== EC2インスタンスを停止するLambda関数
  def aws_stop_ec2_function
    Humidifier::Lambda::Function.new(
      handler: "index.handler",
      role: Humidifier.fn.get_att(["LambdaExecutionRole", "Arn"]),
      code: {
        zip_file: <<-EOS
const INSTANCE_IDS = [#{ENV["EC2_INSTANCE_IDS"]}];

var AWS = require('aws-sdk');
AWS.config.region = "#{ENV["AWS_REGION"]}";

function ec2Stop(callback){
  var ec2 = new AWS.EC2();
  var params = {
    InstanceIds: INSTANCE_IDS
  };

  ec2.stopInstances(params, function(err, data) {
    if (!!err) {
      console.log(err, err.stack);
    } else {
      console.log(data);
      callback();
    }
  });
}
exports.handler = function(event, context) {
  console.log('start');
  ec2Stop(function() {
    context.done(null, 'Stoped Instance');
  });
};
    EOS
      },
      runtime: "nodejs4.3"
    )
  end
end
