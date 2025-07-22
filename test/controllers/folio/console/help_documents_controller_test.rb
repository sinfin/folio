# frozen_string_literal: true

require "test_helper"

class Folio::Console::HelpDocumentsControllerTest < Folio::Console::BaseControllerTest
  def setup
    super
    
    @test_config_dir = Rails.root.join("tmp", "test_help")
    @test_config_file = @test_config_dir.join("index.yml")
    
    # Create test directory
    FileUtils.mkdir_p(@test_config_dir)
    
    # Stub the configuration path
    test_config_file = @test_config_file
    test_config_dir = @test_config_dir
    
    Folio::HelpDocument.singleton_class.class_eval do
      alias_method :original_config_path, :config_path
      alias_method :original_help_directory, :help_directory
      
      define_method(:config_path) { test_config_file }
      define_method(:help_directory) { test_config_dir }
    end
    
    # Create test configuration
    create_test_config_file({
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
    File.write(@test_config_dir.join("test-guide.md"), "# Test Guide\n\nThis is a test guide.")
    File.write(@test_config_dir.join("troubleshooting.md"), "# Troubleshooting\n\nCommon issues.")
  end

  def teardown
    super
    
    # Clean up test files
    FileUtils.rm_rf(@test_config_dir) if @test_config_dir.exist?
    
    # Restore original methods
    Folio::HelpDocument.singleton_class.class_eval do
      if method_defined?(:original_config_path)
        alias_method :config_path, :original_config_path
        remove_method :original_config_path
      end
      
      if method_defined?(:original_help_directory)
        alias_method :help_directory, :original_help_directory
        remove_method :original_help_directory
      end
    end
    
    # Reset any cached data
    Folio::HelpDocument.reload!
  end

  test "index renders successfully" do
    get console_help_documents_path
    assert_response :success
    assert_select "h1", text: /Help Documentation|Nápověda/
  end

  test "index shows configured documents" do
    get console_help_documents_path
    assert_response :success
    
    assert_select ".card-title", text: "Test Guide"
    assert_select ".card-title", text: "Troubleshooting"
    assert_select ".card-text", text: "A comprehensive test guide"
    assert_select ".card-text", text: "Common issues and solutions"
  end

  test "index groups documents by category" do
    get console_help_documents_path
    assert_response :success
    
    assert_select "h2", text: "Guides"
    assert_select "h2", text: "Support"
  end

  test "index shows no documents message when empty" do
    # Create empty configuration
    create_test_config_file({ "documents" => [] })
    
    get console_help_documents_path
    assert_response :success
    assert_select ".alert-info"
  end

  test "show renders document successfully" do
    get console_help_document_path("test-guide")
    assert_response :success
    
    assert_select "h1", text: "Test Guide"
    assert_select ".folio-console-help-content", text: /This is a test guide/
  end

  test "show includes back to list link" do
    get console_help_document_path("test-guide")
    assert_response :success
    
    assert_select "a[href='#{console_help_documents_path}']"
  end

  test "show displays last updated time" do
    get console_help_document_path("test-guide")
    assert_response :success
    
    assert_select ".card-footer", text: /Last updated:|Poslední aktualizace:/
  end

  test "show handles nonexistent document" do
    get console_help_document_path("nonexistent")
    assert_redirected_to console_help_documents_path
    assert_not_nil flash[:danger]
  end

  test "admin role can access help documents" do
    get console_help_documents_path
    assert_response :success
  end

  test "show includes mermaid controller data attribute" do
    get console_help_document_path("test-guide")
    assert_response :success
    
    assert_select ".folio-console-help-content[data-controller='f-mermaid']"
    assert_select ".folio-console-help-content[data-has-mermaid='true']"
  end

  test "index works when no configuration exists" do
    # Remove configuration file
    File.delete(@test_config_file) if File.exist?(@test_config_file)
    
    get console_help_documents_path
    assert_response :success
    assert_select ".alert-info"
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
    
    File.write(@test_config_dir.join("test-guide.md"), markdown_content)
    
    get console_help_document_path("test-guide")
    assert_response :success
    
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

  def create_test_config_file(config)
    File.write(@test_config_file, config.to_yaml)
  end
end 