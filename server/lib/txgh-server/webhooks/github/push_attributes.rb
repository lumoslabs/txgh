require 'set'

module TxghServer
  module Webhooks
    module Github
      class PushAttributes
        ATTRIBUTES = [
          :repo_name, :ref, :before, :after,
          :added_files, :modified_files, :author
        ]

        class << self
          def from_webhook_payload(payload)
            new(
              ATTRIBUTES.each_with_object({}) do |attr, ret|
                ret[attr] = send(attr, payload)
              end
            )
          end

          private

          def repo_name(payload)
            payload['repository']['full_name']
          end

          def ref(payload)
            payload['ref']
          end

          def before(payload)
            payload['before']
          end

          def after(payload)
            payload['after']
          end

          def added_files(payload)
            extract_files(payload, 'added')
          end

          def modified_files(payload)
            extract_files(payload, 'modified')
          end

          def author(payload)
            payload['head_commit']['committer']['name']
          end

          def extract_files(payload, state)
            Set.new(payload['commits'].flat_map { |c| c[state] })
          end
        end

        def files
          @files ||= added_files.merge(modified_files)
        end

        attr_reader *ATTRIBUTES

        def initialize(options = {})
          ATTRIBUTES.each do |attr|
            instance_variable_set(
              "@#{attr}", options.fetch(attr) { options.fetch(attr.to_s) }
            )
          end
        end

        def to_h
          ATTRIBUTES.each_with_object({}) do |attr, ret|
            ret[attr] = instance_variable_get("@#{attr}")
          end
        end

      end
    end
  end
end
