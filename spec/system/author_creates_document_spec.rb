require "rails_helper"

RSpec.describe "Author creates a document", type: :system do
  it "signs in and creates a post, then adds a markdown block" do
    author = create(:author, password: "password123")
    visit new_author_session_path
    fill_in "Email", with: author.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    visit new_author_document_path
    fill_in "Title", with: "Turbo Doc"
    fill_in "Description", with: "Test"
    check "Published"
    click_button "Create Document"

    expect(page).to have_content("Edit Document")
    # Add block
    select "Markdown", from: "block_type", visible: false rescue nil
    fill_in "block_data_markdown", with: "# Hello"
    click_button "Add Block"
    expect(page).to have_content("MarkdownBlock")
  end
end
