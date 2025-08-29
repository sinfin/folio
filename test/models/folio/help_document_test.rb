# frozen_string_literal: true

require "test_helper"

class Folio::HelpDocumentTest < ActiveSupport::TestCase
  attr_reader :test_config_file
  attr_reader :test_markdown_file
  attr_reader :test_config_dir

  def setup
    @test_config_dir = Pathname.new(Dir.mktmpdir("test_help", Rails.root.join("tmp"))) # each test gets its own tmpdir
    @test_config_file = @test_config_dir.join("index.yml")
    @test_markdown_file = @test_config_dir.join("test-doc.md")

    # Folio::HelpDocument.singleton_class.class_eval do
    #   alias_method :original_config_path, :config_path
    #   alias_method :original_help_directory, :help_directory

    #   define_method(:config_path) { test_config_file }
    #   define_method(:help_directory) { test_config_dir }
    # end
  end

  def teardown
    # Clean up test files
    FileUtils.remove_entry test_config_dir

    # Reset any cached data
    Folio::HelpDocument.reload!
  end

  test "config_exists? returns false when no config file" do
    stub_configs do
      assert_not Folio::HelpDocument.config_exists?
    end
  end

  test "config_exists? returns true when config file exists" do
    create_test_config_file({
      "documents" => []
    })

    stub_configs do
      assert Folio::HelpDocument.config_exists?
    end
  end

  test "all returns empty array when no config" do
    stub_configs do
      assert_equal [], Folio::HelpDocument.all
    end
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
    documents = stub_configs do
      Folio::HelpDocument.all
    end
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

    documents = stub_configs do
      Folio::HelpDocument.all
    end
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

    stub_configs do
      doc = Folio::HelpDocument.find("test-doc")
      assert_not_nil doc
      assert_equal "test-doc", doc.slug

      assert_nil Folio::HelpDocument.find("nonexistent")
    end
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

    stub_configs do
      doc = Folio::HelpDocument.find("test-doc")
      assert_equal content, doc.content
    end
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

    stub_configs do
      doc = Folio::HelpDocument.find("test-doc")
      assert_equal "", doc.content
    end
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

    stub_configs do
      existing_doc = Folio::HelpDocument.find("existing-doc")
      missing_doc = Folio::HelpDocument.find("missing-doc")

      assert existing_doc.exists?
      assert_not missing_doc.exists?
    end
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

    stub_configs do
      doc = Folio::HelpDocument.find("test-doc")
      assert_instance_of Time, doc.updated_at
      assert doc.updated_at <= Time.current
    end
  end

  test "handles invalid YAML gracefully" do
    File.write(@test_config_file, "invalid: yaml: content: [")

    # Should not raise an error
    stub_configs do
      documents = Folio::HelpDocument.all
      assert_equal [], documents
    end
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

    stub_configs do
      documents = Folio::HelpDocument.all
      assert_equal 1, documents.length
      assert_equal "valid-doc", documents.first.slug
    end
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

    document = stub_configs do
      Folio::HelpDocument.find("test-doc")
    end

    # Test that updated_at returns a valid time even when git operations might fail
    assert_instance_of Time, document.updated_at

    # Should be close to file modification time
    # Allow for small time differences (git vs filesystem time)
    assert_in_delta(::File.mtime(@test_markdown_file),
                    document.updated_at,
                    300,
                    "Updated time should be close to filesystem time")
  end

  private
    def create_test_config_file(config)
      File.write(@test_config_file, config.to_yaml)
    end

    def create_test_markdown_file(content)
      File.write(@test_markdown_file, content)
    end

    def stub_configs(&block)
      Folio::HelpDocument.stub(:config_path, test_config_file) do
        Folio::HelpDocument.stub(:help_directory, test_config_dir, &block)
      end
    end
end
