require 'rails_helper'

RSpec.describe CodeBlock, type: :model do
  it { should belong_to(:language).optional }

  describe "#plain_text" do
    it "returns code from data hash" do
      block = create(:code_block, data: { "code" => "puts 'Hello, World!'" })
      expect(block.plain_text).to eq("puts 'Hello, World!'")
    end
  end

  describe "#languages" do
    it "returns language extension when language association exists" do
      language = create(:language, name: "Ruby", extension: "rb")
      block = create(:code_block, language: language, data: { "code" => "puts 1" })

      expect(block.languages).to eq([ "rb" ])
    end

    it "returns language from data hash when no association" do
      block = create(:code_block, language: nil, data: { "language" => "Python", "code" => "print(1)" })

      expect(block.languages).to eq([ "python" ])
    end

    it "returns empty array when no language info" do
      block = create(:code_block, language: nil, data: { "code" => "some code" })

      expect(block.languages).to eq([])
    end
  end

  describe "#language_name" do
    it "returns language name from association" do
      language = create(:language, name: "Ruby", extension: "rb")
      block = create(:code_block, language: language)

      expect(block.language_name).to eq("Ruby")
    end

    it "returns language from data hash when no association" do
      block = create(:code_block, language: nil, data: { "language" => "Python" })

      expect(block.language_name).to eq("Python")
    end
  end

  describe "#language_name=" do
    it "finds or creates language and assigns association" do
      block = build(:code_block)

      block.language_name = "ruby"

      expect(block.language).to be_present
      expect(block.language.name).to eq("Ruby")
      expect(block.data["language"]).to eq("ruby")
    end

    it "handles blank language name" do
      block = build(:code_block)

      block.language_name = ""

      expect(block.language).to be_nil
    end
  end

  describe "#filename" do
    it "returns filename from data hash" do
      block = create(:code_block, data: { "filename" => "test.rb", "code" => "puts 1" })

      expect(block.filename).to eq("test.rb")
    end
  end

  describe "#filename=" do
    it "sets filename in data hash" do
      block = create(:code_block, data: { "code" => "puts 1" })

      block.filename = "script.rb"

      expect(block.data["filename"]).to eq("script.rb")
    end
  end

  describe "#can_be_interactive?" do
    it "returns true when language supports interactivity" do
      language = create(:language, interactive: true)
      block = create(:code_block, language: language)

      expect(block.can_be_interactive?).to be true
    end

    it "returns false when language does not support interactivity" do
      language = create(:language, interactive: false)
      block = create(:code_block, language: language)

      expect(block.can_be_interactive?).to be false
    end

    it "returns falsey when no language association" do
      block = create(:code_block, language: nil)

      expect(block.can_be_interactive?).to be_falsey
    end
  end

  describe "#supports_execution?" do
    it "returns true when interactive and language supports execution" do
      language = create(:language, interactive: true, executable_command: "ruby")
      block = create(:code_block, language: language, interactive: true)

      expect(block.supports_execution?).to be true
    end

    it "returns false when not interactive" do
      language = create(:language, interactive: true, executable_command: "ruby")
      block = create(:code_block, language: language, interactive: false)

      expect(block.supports_execution?).to be false
    end

    it "returns false when language does not support execution" do
      language = create(:language, interactive: true, executable_command: nil)
      block = create(:code_block, language: language, interactive: true)

      expect(block.supports_execution?).to be false
    end
  end

  describe "#execution_result" do
    it "returns execution result from data hash when supports execution" do
      language = create(:language, interactive: true, executable_command: "ruby")
      block = create(:code_block,
        language: language,
        interactive: true,
        data: { "code" => "puts 1", "execution_result" => { "output" => "1\n" } }
      )

      expect(block.execution_result).to eq({ "output" => "1\n" })
    end

    it "returns nil when does not support execution" do
      block = create(:code_block, interactive: false)

      expect(block.execution_result).to be_nil
    end
  end

  describe "#set_execution_result" do
    it "stores execution result in data hash" do
      block = create(:code_block)
      result = { "output" => "Hello", "status" => "success" }

      block.set_execution_result(result)

      expect(block.data["execution_result"]).to eq(result)
    end
  end

  describe "validation" do
    it "prevents interactive mode for non-interactive languages" do
      language = create(:language, interactive: false)
      block = build(:code_block, language: language, interactive: true)

      expect(block).not_to be_valid
      expect(block.errors[:interactive]).to include("cannot be enabled for languages that don't support interactivity")
    end

    it "allows interactive mode for interactive languages" do
      language = create(:language, interactive: true)
      block = build(:code_block, language: language, interactive: true)

      expect(block).to be_valid
    end
  end

  describe "auto_disable_interactive callback" do
    it "disables interactive when language does not support it" do
      language = create(:language, interactive: false)
      block = CodeBlock.new(
        document: create(:document),
        position: 1,
        data: { "code" => "test" },
        language: language
      )
      block.interactive = true

      # Save bypasses validation since validation would reject it
      block.save(validate: false)

      expect(block.reload.interactive).to be false
    end

    it "keeps interactive enabled for supported languages" do
      language = create(:language, interactive: true)
      block = CodeBlock.create!(
        document: create(:document),
        position: 1,
        data: { "code" => "test" },
        language: language,
        interactive: true
      )

      block.save

      expect(block.interactive).to be true
    end
  end
end
