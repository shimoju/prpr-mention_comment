module Prpr
  module Action
    module MentionComment
      class Mention < Base
        REGEXP = /@[a-zA-Z0-9_-]+/

        def call
          if mention?
            Publisher::Adapter::Base.broadcast message
          end
        end

        private

        def message
          Prpr::Publisher::Message.new(body: body, from: from, room: room)
        end

        def mention?
          comment.body =~ REGEXP
        end

        def body
          <<-END
#{comment_body}

#{comment.html_url}
          END
        end

        def comment_body
          comment.body.gsub(REGEXP) { |old|
            members[old] || old
          }
        end

        def comment
          event.comment
        end

        def from
          event.sender
        end

        def room
          env[:mention_comment_room]
        end

        def members
          @members ||= config.read(name).lines.map { |line|
            if line =~ / \* (\S+):\s*(\S+)/
              [$1, $2]
            end
          }.to_h
        rescue
          @members ||= {}
        end

        def config
          @config ||= Config::Github.new(repository_name)
        end

        def env
          Config::Env.default
        end

        def name
          env[:mention_comment_members] || 'MEMBERS.md'
        end

        def repository_name
          env[:mention_comment_members_repository] || event.repository.full_name
        end
      end
    end
  end
end
