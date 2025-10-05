# frozen_string_literal: true

# MergePreserveAllHash refinement
#
# Usage (example in a helper):
#   require_dependency Rails.root.join("lib/merge_preserve_all_hash").to_s
#   using MergePreserveAllHash
#
#   defaults = { class: "a", data: { x: 1 } }
#   opts     = { class: "b", data: { y: 2 } }
#   merged   = defaults.merge_preserve_all(opts)
#
# Behavior:
# - recursively merges Hash values
# - concatenates Arrays
# - for two Strings (by default) returns joined String "left right"
# - otherwise preserves both values in an Array [left, right]
# - keys are normalized to symbols in the returned Hash
module MergePreserveAllHash
  refine Hash do
    # Merge another hash while preserving both side's values for conflicts.
    #
    # other - Hash-like to merge in (defaults are assumed to be `self`)
    # join_strings - when true (default), join two String values with a space
    #
    # Returns a new Hash with symbol keys.
    def merge_preserve_all(other = {}, join_strings: true)
      other = (other || {}).to_h

      # normalize keys to symbols for consistent lookup
      d = self.transform_keys { |k| k.to_sym }
      o = other.transform_keys { |k| k.to_sym }

      all_keys = (d.keys | o.keys)

      all_keys.each_with_object({}) do |key, out|
        if d.key?(key) && o.key?(key)
          a = d[key]
          b = o[key]

          out[key] =
            if a.is_a?(Hash) && b.is_a?(Hash)
              # recursive merge for nested hashes
              a.merge_preserve_all(b, join_strings: join_strings)
            elsif a.is_a?(Array) && b.is_a?(Array)
              # concat arrays
              a + b
            elsif a.is_a?(Array)
              a + [ b ]
            elsif b.is_a?(Array)
              [ a ] + b
            elsif a.is_a?(String) && b.is_a?(String) && join_strings
              # join strings (useful for :class)
              [ a, b ].compact.map(&:to_s).map(&:strip).reject(&:empty?).join(" ")
            else
              # preserve both in array
              [ a, b ]
            end
        elsif d.key?(key)
          out[key] = d[key]
        else
          out[key] = o[key]
        end
      end
    end
  end
end
