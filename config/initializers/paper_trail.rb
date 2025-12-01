# PaperTrail configuration for safe YAML deserialization
# Required for Ruby 3.1+ which has stricter YAML.safe_load security

# Configure PaperTrail to use JSON serialization instead of YAML
# This avoids the YAML.safe_load security issues with ActiveSupport classes
PaperTrail.serializer = PaperTrail::Serializers::JSON

# Alternative: If you need YAML, configure permitted classes
# Uncomment and use this if you specifically need YAML serialization:
#
# module PaperTrail
#   module Serializers
#     module YAML
#       def self.load(string)
#         ::YAML.safe_load(
#           string,
#           permitted_classes: [
#             Symbol,
#             Date,
#             Time,
#             ActiveSupport::TimeWithZone,
#             ActiveSupport::TimeZone,
#             ActiveSupport::HashWithIndifferentAccess,
#             BigDecimal
#           ],
#           aliases: true
#         )
#       end
#
#       def self.dump(object)
#         ::YAML.dump(object)
#       end
#     end
#   end
# end
