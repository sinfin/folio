# frozen_string_literal: true

require "test_helper"

class Folio::HelpDocumentTest < ActiveSupport::TestCase
  def setup
    @test_config_dir = Rails.root.join("tmp", "test_help")
    @test_config_file = @test_config_dir.join("index.yml")
    @test_markdown_file = @test_config_dir.join("test-doc.md")
    
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
  end

  def teardown
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

  test "config_exists? returns false when no config file" do
    assert_not Folio::HelpDocument.config_exists?
  end

  test "config_exists? returns true when config file exists" do
    create_test_config_file({
      "documents" => []
    })
    
    assert Folio::HelpDocument.config_exists?
  end

  test "all returns empty array when no config" do
    assert_equal [], Folio::HelpDocument.all
  end

  test "all returns documents from valid config" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "test-doc",
          "title" => "Test Document",
          "description" => "A test document",
          "order" => 1,
          "category" => "Test"
        }
      ]
    })
    
    create_test_markdown_file("# Test Content")
    
    documents = Folio::HelpDocument.all
    assert_equal 1, documents.length
    
    doc = documents.first
    assert_equal "test-doc", doc.slug
    assert_equal "Test Document", doc.title
    assert_equal "A test document", doc.description
    assert_equal 1, doc.order
    assert_equal "Test", doc.category
  end

  test "all sorts documents by order" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "second-doc",
          "title" => "Second Document",
          "order" => 2
        },
        {
          "slug" => "first-doc", 
          "title" => "First Document",
          "order" => 1
        }
      ]
    })
    
    documents = Folio::HelpDocument.all
    assert_equal "first-doc", documents.first.slug
    assert_equal "second-doc", documents.last.slug
  end

  test "find returns correct document" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "test-doc",
          "title" => "Test Document"
        }
      ]
    })
    
    doc = Folio::HelpDocument.find("test-doc")
    assert_not_nil doc
    assert_equal "test-doc", doc.slug
    
    assert_nil Folio::HelpDocument.find("nonexistent")
  end

  test "content returns file contents when file exists" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "test-doc",
          "title" => "Test Document"
        }
      ]
    })
    
    content = "# Test Markdown\n\nThis is test content."
    create_test_markdown_file(content)
    
    doc = Folio::HelpDocument.find("test-doc")
    assert_equal content, doc.content
  end

  test "content returns empty string when file does not exist" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "test-doc",
          "title" => "Test Document"
        }
      ]
    })
    
    doc = Folio::HelpDocument.find("test-doc")
    assert_equal "", doc.content
  end

  test "exists? returns correct boolean" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "existing-doc",
          "title" => "Existing Document"
        },
        {
          "slug" => "missing-doc",
          "title" => "Missing Document"
        }
      ]
    })
    
    # Create only one markdown file
    File.write(@test_config_dir.join("existing-doc.md"), "Content")
    
    existing_doc = Folio::HelpDocument.find("existing-doc")
    missing_doc = Folio::HelpDocument.find("missing-doc")
    
    assert existing_doc.exists?
    assert_not missing_doc.exists?
  end

  test "updated_at returns file modification time" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "test-doc",
          "title" => "Test Document"
        }
      ]
    })
    
    create_test_markdown_file("Content")
    
    doc = Folio::HelpDocument.find("test-doc")
    assert_instance_of Time, doc.updated_at
    assert doc.updated_at <= Time.current
  end

  test "handles invalid YAML gracefully" do
    File.write(@test_config_file, "invalid: yaml: content: [")
    
    # Should not raise an error
    documents = Folio::HelpDocument.all
    assert_equal [], documents
  end

  test "skips documents without slug" do
    create_test_config_file({
      "documents" => [
        {
          "title" => "Document without slug"
        },
        {
          "slug" => "valid-doc",
          "title" => "Valid Document"
        }
      ]
    })
    
    documents = Folio::HelpDocument.all
    assert_equal 1, documents.length
    assert_equal "valid-doc", documents.first.slug
  end

  test "updated_at gracefully handles git unavailability" do
    create_test_config_file({
      "documents" => [
        {
          "slug" => "test-doc",
          "title" => "Test Doc",
          "path" => @test_markdown_file.to_s
        }
      ]
    })
    
    create_test_markdown_file("# Test content")
    document = Folio::HelpDocument.find("test-doc")
    
    # Test that updated_at returns a valid time even when git operations might fail
    assert_instance_of Time, document.updated_at
    
    # Should be close to file modification time
    filesystem_time = ::File.mtime(@test_markdown_file)
    time_difference = (document.updated_at - filesystem_time).abs
    
    # Allow for small time differences (git vs filesystem time)
    assert time_difference < 300, "Updated time should be close to filesystem time"
  end

  private

  def create_test_config_file(config)
    File.write(@test_config_file, config.to_yaml)
  end

  def create_test_markdown_file(content)
    File.write(@test_markdown_file, content)
  end
end 