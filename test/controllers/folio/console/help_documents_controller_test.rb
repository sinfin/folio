# frozen_string_literal: true

require "test_helper"

class Folio::Console::HelpDocumentsControllerTest < Folio::Console::BaseControllerTest
  attr_reader :x_test_config_file
  attr_reader :x_test_config_dir

  def setup
    super

    @x_test_config_dir = Pathname.new(Dir.mktmpdir("test_help", Rails.root.join("tmp"))) # each test gets its own tmpdir
    @x_test_config_file = @x_test_config_dir.join("index.yml")

    # Create test configuration
    create_x_test_config_file({
      "documents" => [
        {
          "slug" => "test-guide",
          "title" => "Test Guide",
          "description" => "A comprehensive test guide",
          "order" => 1,
          "category" => "Guides"
        },
        {
          "slug" => "troubleshooting",
          "title" => "Troubleshooting",
          "description" => "Common issues and solutions",
          "order" => 2,
          "category" => "Support"
        }
      ]
    })

    # Create test markdown files
    File.write(@x_test_config_dir.join("test-guide.md"), "# Test Guide\n\nThis is a test guide.")
    File.write(@x_test_config_dir.join("troubleshooting.md"), "# Troubleshooting\n\nCommon issues.")
  end

  def teardown
    super

    # Clean up test files
    FileUtils.remove_entry x_test_config_dir

    # Reset any cached data
    Folio::HelpDocument.reload!
  end

  test "index renders successfully" do
    stub_configs do
      get console_help_documents_path
      assert_response :success
      assert_select "h1", text: /Help Documentation|Nápověda/
    end
  end

  test "index shows configured documents" do
    stub_configs do
      get console_help_documents_path
      assert_response :success

      assert_select ".card-title", text: "Test Guide"
      assert_select ".card-title", text: "Troubleshooting"
      assert_select ".card-text", text: "A comprehensive test guide"
      assert_select ".card-text", text: "Common issues and solutions"
    end
  end

  test "index groups documents by category" do
    stub_configs do
      get console_help_documents_path
      assert_response :success

      assert_select "h2", text: "Guides"
      assert_select "h2", text: "Support"
    end
  end

  test "index shows no documents message when empty" do
    # Create empty configuration
    create_x_test_config_file({ "documents" => [] })
    stub_configs do
      get console_help_documents_path
      assert_response :success
      assert_select ".alert-info"
    end
  end

  test "show renders document successfully" do
    stub_configs do
      get console_help_document_path("test-guide")
      assert_response :success

      assert_select "h1", text: "Test Guide"
      assert_select ".folio-console-help-content", text: /This is a test guide/
    end
  end

  test "show includes back to list link" do
    stub_configs do
      get console_help_document_path("test-guide")
      assert_response :success

      assert_select "a[href='#{console_help_documents_path}']"
    end
  end

  test "show displays last updated time" do
    stub_configs do
      get console_help_document_path("test-guide")
      assert_response :success

      assert_select ".card-footer", text: /Last updated:|Poslední aktualizace:/
    end
  end

  test "show handles nonexistent document" do
    stub_configs do
      get console_help_document_path("nonexistent")
      assert_redirected_to console_help_documents_path
      assert_not_nil flash[:danger]
    end
  end

  test "admin role can access help documents" do
    stub_configs do
      get console_help_documents_path
      assert_response :success
    end
  end

  test "show includes mermaid controller data attribute" do
    stub_configs do
      get console_help_document_path("test-guide")
      assert_response :success

      assert_select ".folio-console-help-content[data-controller='f-mermaid']"
      assert_select ".folio-console-help-content[data-has-mermaid='true']"
    end
  end

  test "index works when no configuration exists" do
    # Remove configuration file
    File.delete(@x_test_config_file) if File.exist?(@x_test_config_file)

    stub_configs do
      get console_help_documents_path
      assert_response :success
      assert_select ".alert-info"
    end
  end

  test "renders markdown content correctly" do
    # Create a document with various markdown elements
    markdown_content = <<~MARKDOWN
      # Main Title

      ## Subtitle

      This is **bold** text and *italic* text.

      - List item 1
      - List item 2

      ```ruby
      def hello
        puts "Hello World"
      end
      ```

      | Column 1 | Column 2 |
      |----------|----------|
      | Value 1  | Value 2  |
    MARKDOWN

    File.write(@x_test_config_dir.join("test-guide.md"), markdown_content)

    stub_configs do
      get console_help_document_path("test-guide")
      assert_response :success
    end

    # Check that markdown was converted to HTML
    assert_select "h1", text: "Main Title"
    assert_select "h2", text: "Subtitle"
    assert_select "strong", text: "bold"
    assert_select "em", text: "italic"
    assert_select "ul li", text: "List item 1"
    assert_select "pre code"
    assert_select "table"
  end

  private
    def create_x_test_config_file(config)
      File.write(@x_test_config_file, config.to_yaml)
    end

    def stub_configs(&block)
      Folio::HelpDocument.stub(:config_path, x_test_config_file) do
        Folio::HelpDocument.stub(:help_directory, x_test_config_dir, &block)
      end
    end
end
