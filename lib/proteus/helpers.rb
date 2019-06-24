require 'pty'
require 'json'
require 'net/http'
require 'proteus/helpers/path_helpers'
require 'date'
require 'etc'

module Proteus
  module Helpers
    include Proteus::Helpers::PathHelpers

    ERROR = :red
    DEFAULT = :green

    def alert(message)
      say "#{message}", :on_red
    end

    def limit(resources)
      resources ? resources.inject("") {
        |memo, resource| "#{memo} -target=#{resource}" } : ""
    end

    def confirm(question:, color:, exit_on_no: true, exit_code: 1)
      if ask(question, color, limited_to: ["yes", "no"]) == "yes"
        yield if block_given?
      else
        if exit_on_no
          say "Exiting.", ERROR
          exit exit_code
        end
      end
    end

    def current_user
      Etc.getpwnam(Etc.getlogin).gecos
    end

    def slack_webhook
      hook = config[:slack_webhooks].find do |h|
        environment =~ /#{h[:match]}/
      end

      hook ? hook[:url] : nil
    end

    def slack_notification(context:, environment:, message:)
      webhook_url = slack_webhook

      if webhook_url
        time = DateTime.now.strftime("%Y/%m/%d - %H:%M")
        slack_payload = {
          text: "[#{context} - #{environment} - #{time}] #{current_user} #{message}"
        }.to_json

        uri = URI(webhook_url)

        request = Net::HTTP::Post.new(uri)
        request.body = slack_payload

        request_options = {
          use_ssl: uri.scheme == "https",
        }

        Net::HTTP::start(uri.hostname, uri.port, request_options) do |http|
          http.request(request)
        end
      end
    end

    def syscall(command, dryrun: false, capture: false, suppress: false)
      say "Executing: #{command}\n\n", :green

      output = ""

      if not dryrun
        begin
          PTY.spawn(command) do |stdout, stdin, pid|
            stdout.each do |line|
              output << line
              puts line unless suppress
            end
          end
        rescue Errno::EIO # GNU/Linux raises EIO.
          nil
        end
      end
      return output
    end
  end
end
