require 'proteus/commands/apply'
require 'proteus/commands/clean'
require 'proteus/commands/destroy'
require 'proteus/commands/graph'
require 'proteus/commands/import'
require 'proteus/commands/move'
require 'proteus/commands/output'
require 'proteus/commands/plan'
require 'proteus/commands/remove'
require 'proteus/commands/render'
require 'proteus/commands/taint'

module Proteus
  class Common < Thor
    include Helpers
    include Proteus::Helpers::PathHelpers

    Proteus::Commands.constants.each do |command|
      include const_get("Proteus::Commands::#{command}")
    end

    private

    def context
      self.class.context
    end

    def environment
      self.class.environment
    end

    def render_backend
      Proteus::Backend::Backend.new(config: config, context: context, environment: environment).render
    end

    def init(verbose: false)
      say "initializing", :green
      say "environment: #{environment}", :green

      render_backend

      `rm -rf #{context_path(context)}/.terraform/*.tf*`
      `rm -rf #{context_path(context)}/.terraform/modules`
      `rm -rf #{context_path(context)}/terraform.tfstate*`

      terraform_command = <<~TERRAFORM_COMMAND
        cd #{context_path(context)} && \
        terraform init \
        -backend-config='key=#{config[:backend][:key_prefix]}#{context}-#{environment}.tfstate' \
        #{aws_profile} \
        #{context_path(context)}
      TERRAFORM_COMMAND

      output = syscall terraform_command.squeeze(' '), suppress: true, capture: true
      say(output, :green) if verbose
    end

    def aws_profile
      config[:providers].select {|p| p[:name] == 'aws' }.first[:environments].each do |provider|
        return "-var 'aws_profile=#{provider[:profile]}'" if environment =~ (/#{provider[:match]}/)
      end
      return ""
    end

    def dryrun
      parent_options[:dryrun]
    end

  end
end
