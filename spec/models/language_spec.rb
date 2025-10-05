require 'rails_helper'

RSpec.describe Language, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:extension) }

  it "validates uniqueness of name" do
    create(:language, name: "Ruby", extension: "rb")
    duplicate = build(:language, name: "Ruby", extension: "rb2")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include("has already been taken")
  end

  describe ".find_or_create_by_name" do
    it "finds existing language case-insensitively" do
      existing = create(:language, name: "Ruby", extension: "rb")

      result = Language.find_or_create_by_name("ruby")

      expect(result).to eq(existing)
      expect(Language.count).to eq(1)
    end

    it "creates new language when not found" do
      result = Language.find_or_create_by_name("python")

      expect(result).to be_persisted
      expect(result.name).to eq("Python") # titleized
      expect(result.extension).to eq("python")
      expect(result.interactive).to be false
    end

    it "returns nil for blank name" do
      expect(Language.find_or_create_by_name("")).to be_nil
      expect(Language.find_or_create_by_name(nil)).to be_nil
    end

    it "handles creation failures gracefully" do
      # Create a language without extension to trigger validation error
      allow(Language).to receive(:create).and_raise(ActiveRecord::RecordInvalid)

      result = Language.find_or_create_by_name("invalid")

      expect(result).to be_nil
    end
  end

  describe "#supports_execution?" do
    it "returns true when interactive and has executable_command" do
      language = create(:language, interactive: true, executable_command: "python3")

      expect(language.supports_execution?).to be true
    end

    it "returns false when not interactive" do
      language = create(:language, interactive: false, executable_command: "python3")

      expect(language.supports_execution?).to be false
    end

    it "returns false when no executable_command" do
      language = create(:language, interactive: true, executable_command: nil)

      expect(language.supports_execution?).to be false
    end

    it "returns false when executable_command is blank" do
      language = create(:language, interactive: true, executable_command: "")

      expect(language.supports_execution?).to be false
    end
  end

  describe "scopes" do
    it "filters interactive languages" do
      interactive = create(:language, name: "Python", extension: "py", interactive: true)
      non_interactive = create(:language, name: "Text", extension: "txt", interactive: false)

      expect(Language.interactive).to include(interactive)
      expect(Language.interactive).not_to include(non_interactive)
    end

    it "orders by name" do
      lang_z = create(:language, name: "Zig", extension: "zig")
      lang_a = create(:language, name: "Ada", extension: "ada")
      lang_m = create(:language, name: "Mojo", extension: "mojo")

      expect(Language.by_name.pluck(:name)).to eq([ "Ada", "Mojo", "Zig" ])
    end
  end
end
