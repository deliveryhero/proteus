module Proteus
  module Config
    def config
      unless @config
        @config = YAML.load(File.read(File.expand_path(config_path))).with_indifferent_access
        begin
          validator = ConfigValidator.new(@config)
        rescue Proteus::Validators::ValidationError => validation_error
          say "ConfigValidator: #{validation_error.message} [#{config_path}] #{"\u2718".encode('utf-8')}", :red
          exit 1
        end
      end

      @config
    end

    class ConfigValidator < Proteus::Validators::BaseValidator
      def validate
        within :providers do
          ensure_data_type Array

          each do
            ensure_keys :name

            within :environments do
              ensure_uniqueness_across :match

              each do
                ensure_keys :profile, :backend
              end
            end
          end
        end

        within :slack_webhooks, optional: true do
          ensure_data_type Array

          each do
            ensure_keys :match, :url
          end
        end

        within :backend do
          each_key do
            ensure_presence :key_prefix

            within :bucket do
              ensure_keys :name, :region, :profile
            end
          end
        end
      end
    end
  end
end
