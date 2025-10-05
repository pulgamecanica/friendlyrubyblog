require 'rails_helper'
require_dependency Rails.root.join("lib/merge_preserve_all_hash").to_s

RSpec.describe MergePreserveAllHash do
  using MergePreserveAllHash

  describe "#merge_preserve_all" do
    context "with simple hash merging" do
      it "merges non-conflicting keys" do
        a = { name: "Alice" }
        b = { age: 30 }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ name: "Alice", age: 30 })
      end

      it "normalizes keys to symbols" do
        a = { "name" => "Alice" }
        b = { "age" => 30 }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ name: "Alice", age: 30 })
      end
    end

    context "with string values" do
      it "joins two string values with space by default" do
        a = { class: "btn" }
        b = { class: "primary" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ class: "btn primary" })
      end

      it "strips whitespace when joining strings" do
        a = { class: "btn " }
        b = { class: " primary" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ class: "btn primary" })
      end

      it "preserves strings in array when join_strings is false" do
        a = { value: "first" }
        b = { value: "second" }

        result = a.merge_preserve_all(b, join_strings: false)

        expect(result).to eq({ value: [ "first", "second" ] })
      end
    end

    context "with array values" do
      it "concatenates two arrays" do
        a = { tags: [ "ruby" ] }
        b = { tags: [ "rails" ] }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ tags: [ "ruby", "rails" ] })
      end

      it "appends non-array value to array" do
        a = { tags: [ "ruby" ] }
        b = { tags: "rails" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ tags: [ "ruby", "rails" ] })
      end

      it "prepends array to non-array value" do
        a = { tags: "ruby" }
        b = { tags: [ "rails", "web" ] }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ tags: [ "ruby", "rails", "web" ] })
      end
    end

    context "with hash values (nested)" do
      it "recursively merges nested hashes" do
        a = { data: { x: 1, y: 2 } }
        b = { data: { y: 3, z: 4 } }

        result = a.merge_preserve_all(b)

        expect(result[:data][:x]).to eq(1)
        expect(result[:data][:y]).to eq([ 2, 3 ])
        expect(result[:data][:z]).to eq(4)
      end

      it "applies join_strings to nested string values" do
        a = { attrs: { class: "outer" } }
        b = { attrs: { class: "inner" } }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ attrs: { class: "outer inner" } })
      end

      it "deeply nests hash merging" do
        a = { level1: { level2: { level3: { value: "a" } } } }
        b = { level1: { level2: { level3: { value: "b" } } } }

        result = a.merge_preserve_all(b)

        expect(result[:level1][:level2][:level3][:value]).to eq("a b")
      end
    end

    context "with mixed types" do
      it "preserves both values in array for different types" do
        a = { value: 42 }
        b = { value: "text" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ value: [ 42, "text" ] })
      end

      it "preserves boolean false values" do
        a = { enabled: false }
        b = { name: "test" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ enabled: false, name: "test" })
      end

      it "preserves nil values" do
        a = { value: nil }
        b = { other: "test" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ value: nil, other: "test" })
      end
    end

    context "with real-world use cases" do
      it "merges HTML attributes correctly" do
        defaults = {
          class: "btn",
          data: { controller: "tooltip", action: "click->tooltip#show" }
        }
        options = {
          class: "btn-primary",
          data: { turbo: false }
        }

        result = defaults.merge_preserve_all(options)

        expect(result[:class]).to eq("btn btn-primary")
        expect(result[:data][:controller]).to eq("tooltip")
        expect(result[:data][:action]).to eq("click->tooltip#show")
        expect(result[:data][:turbo]).to be false
      end

      it "handles complex data attribute merging" do
        a = {
          class: "card",
          data: {
            controller: "dropdown",
            dropdown_open_class: "active"
          }
        }
        b = {
          class: "shadow",
          data: {
            controller: "tooltip",
            tooltip_position_value: "top"
          }
        }

        result = a.merge_preserve_all(b)

        expect(result[:class]).to eq("card shadow")
        expect(result[:data][:controller]).to eq("dropdown tooltip")
        expect(result[:data][:dropdown_open_class]).to eq("active")
        expect(result[:data][:tooltip_position_value]).to eq("top")
      end
    end

    context "with nil or empty hashes" do
      it "handles nil other hash" do
        a = { value: "test" }

        result = a.merge_preserve_all(nil)

        expect(result).to eq({ value: "test" })
      end

      it "handles empty other hash" do
        a = { value: "test" }

        result = a.merge_preserve_all({})

        expect(result).to eq({ value: "test" })
      end

      it "handles empty self hash" do
        a = {}
        b = { value: "test" }

        result = a.merge_preserve_all(b)

        expect(result).to eq({ value: "test" })
      end
    end
  end
end
