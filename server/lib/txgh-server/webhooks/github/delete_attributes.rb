module TxghServer
  module Webhooks
    module Github
      class DeleteAttributes
        ATTRIBUTES = [
          :event, :repo_name, :ref, :ref_type
        ]

        class << self
          def from_webhook_payload(payload)
            new(
              ATTRIBUTES.each_with_object({}) do |attr, ret|
                ret[attr] = send(attr, payload)
              end
            )
          end

          def event(payload)
            'delete'
          end

          def repo_name(payload)
            payload.fetch('repository').fetch('full_name')
          end

          def ref(payload)
            payload.fetch('ref')
          end

          def ref_type(payload)
            payload.fetch('ref_type')
          end
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
