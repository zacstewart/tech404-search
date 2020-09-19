require 'eventmachine'
require 'faye/websocket'
require 'slack/api'
require 'thread'

module Tech404logs
  class Connection
    def initialize(token = ENV['SLACK_TOKEN'])
      @token = token
      @reactor = EM
      @ws = nil
    end

    def start
      # These are run in forks with their own DB connection
      sync_channels
      sync_users

      # Connect to database
      Tech404logs.preboot

      reactor.error_handler(&method(:on_error))
      run
    end

    def run
      reactor.run do
        @ws = Faye::WebSocket::Client.new(url, [])
        @ws.onopen = method(:on_open)
        @ws.onclose = method(:on_close)
        @ws.onmessage = method(:on_message)
        @ws.onerror = method(:on_error)
      end
    end

    def on_error(error)
      warn "Exception raised in event loop: #{error.inspect}"
    end

    def on_open(event)
      logger.debug 'Connected to RTM socket'
    end

    def on_message(event)
      logger.debug "RTM message received: #{event.data}"
      reactor.defer { EventHandler.handle(event.data) }
    end

    def on_close(close)
      logger.debug "RTM connection closed: #{close.code}, #{close.reason}"
      reactor.stop
      run
    end

    private

    attr_reader :reactor, :token, :ws

    def logger
      Tech404logs.logger
    end

    def url
      @url ||= rtm.fetch('url')
    end

    def rtm
      @rtm ||= Slack::Api.new(token).rtm_start
    end

    def sync_channels
      WorkerFork.fork do
        rtm.fetch('channels').each do |channel|
          Channel.create_or_update(channel)
        end
      end
    end

    def sync_users
      WorkerFork.fork do
        user_handler = Handlers::UserHandler.new
        rtm.fetch('users').each do |user|
          user_handler.handle(user)
        end
      end
    end
  end
end
