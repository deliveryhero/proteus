require 'proteus/backend/backend'

module Proteus
  class BackendInfo < Thor
    include Thor::Actions
    include Helpers
    include Config

    desc "backend-info", "Shows information about backend configuration"
    long_desc <<-LONGDESC
      Shows information about backend configuration
    LONGDESC
    def backend_info
      Proteus::Backend::Backend.new(config: config, context: nil, environment: nil).show_backends
    end

    default_task :backend_info
  end
end
