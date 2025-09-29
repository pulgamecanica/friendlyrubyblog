require "rails_helper"

RSpec.describe "Author creates a document", type: :system do
  let(:author) { create(:author, password: "password123") }

  before do
    visit new_author_session_path
    fill_in "Email", with: author.email
    fill_in "Password", with: "password123"
    click_button "Log in"
  end

  it "signs in and creates a post, then adds and edits a markdown block" do
    visit new_author_document_path
    fill_in "Title", with: "Turbo Doc"
    fill_in "Description", with: "Test description"
    click_button "Create Document"

    expect(page).to have_content("Turbo Doc")

    # Add a new markdown block using the new interface
    within "#new_block" do
      fill_in "block_data_markdown", with: "# Hello World"
      click_button "Add Block"
    end

    expect(page).to have_content("MARKDOWNBLOCK")

    # Test the new block editor interface
    # The block should be in normal mode initially, showing rendered content
    expect(page).to have_css("h1", text: "Hello World")

    # Click the block to enter edit mode
    first("[data-block-editor-target='content']").click

    # Should now see the textarea for editing
    expect(page).to have_css("textarea[data-block-editor-target='textarea']")

    # Test live preview functionality
    within "textarea[data-block-editor-target='textarea']" do
      fill_in with: "# Updated Content\n\nThis is **bold** text."
    end

    # Test saving from the toolbar
    click_button "Update Block"

    # Should exit edit mode and show updated content
    expect(page).to have_css("h1", text: "Updated Content")
    expect(page).to have_content("bold")
  end

  it "allows toggling between preview layouts for markdown blocks" do
    document = create(:document, author: author)
    create(:markdown_block, document: document, data: { "markdown" => "# Test Block" })

    visit edit_author_document_path(document)

    # Enter edit mode
    first("[data-block-editor-target='content']").click

    # Should see preview controls in the toolbar - initial button text
    expect(page).to have_button("Hide")  # Preview is visible by default, so button says "Hide"
    expect(page).to have_button("Stack")  # Layout is "side" by default, so button says "Stack"

    # Test hiding preview
    click_button "Hide"
    expect(page).not_to have_css("[data-block-editor-target='preview']", visible: true)

    # Test showing preview again
    click_button "Show"
    expect(page).to have_css("[data-block-editor-target='preview']", visible: true)

    # Test layout toggle
    click_button "Stack"
    # Preview should still be visible but in stacked layout
    expect(page).to have_css("[data-block-editor-target='preview']", visible: true)
  end

  it "supports block collapse functionality" do
    document = create(:document, author: author)
    create(:markdown_block, document: document, data: {
      "markdown" => "# Long Content\n\n" + ("This is a long paragraph. " * 20)
    })

    visit edit_author_document_path(document)

    # Block should start in normal mode
    expect(page).to have_css("[data-block-editor-target='content']", visible: true)

    # Test collapse functionality - initially shows "Collapse"
    click_button "Collapse"

    # Should see fade overlay when collapsed and button should now say "Expand"
    expect(page).to have_css("[data-block-editor-target='fadeOverlay']")
    expect(page).to have_button("Expand")

    # Test expand
    click_button "Expand"

    # Fade overlay should be hidden and button should say "Collapse" again
    expect(page).not_to have_css("[data-block-editor-target='fadeOverlay']", visible: true)
    expect(page).to have_button("Collapse")
  end
end
