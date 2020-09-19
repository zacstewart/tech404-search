module Tech404logs
  module Handlers
    class MessageHandler

      def initialize
        @db = Sequel::Model.db
        @table = Sequel::Model.db[:messages]
        @user_handler = UserHandler.new
      end

      # Returns the id of the inerted Message
      def handle(message)
        case message.fetch('subtype') { :default }
        when :default, 'channel_join', 'channel_leave', 'channel_topic',
          'channel_purpose', 'channel_name', 'channel_archive',
          'channel_unarchive', 'group_join', 'group_leave', 'group_topic',
          'group_purpose', 'group_name', 'group_archive', 'group_unarchive',
          'file_share', 'file_comment', 'file_mention', 'pinned_item',
          'unpinned_item'
          store(message)
        end
      end

      private

      attr_reader :db, :table, :user_handler

      def store(message)
        db.transaction do 
          table.insert(
            channel_id: message.fetch('channel'),
            user_id: user_handler.handle(message.fetch('user')),
            text: message.fetch('text'),
            timestamp: Time.at(Float(message.fetch('ts')))
          )
        end
      end

    end
  end
end
