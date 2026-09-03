# frozen_string_literal: true

require "test_helper"

class Folio::UserByQueryTest < ActiveSupport::TestCase
  # PostgreSQL stores an address as a single `email` lexeme, so a tsearch query
  # only matches when the typed text reaches to_tsquery as one term. The
  # sanitizer in config/initializers/pg_search.rb must therefore leave dots and
  # at-signs alone — splitting them turns "petr.tobiska@volny.cz" into four
  # ANDed prefix terms that can never match.
  def user_with_email(email)
    create(:folio_user, email:, first_name: nil, last_name: nil)
  end

  test "by_query finds a user by their full email address" do
    user = user_with_email("petr.tobiska@volny.cz")

    assert_includes Folio::User.by_query("petr.tobiska@volny.cz").pluck(:id), user.id
  end

  test "by_query finds a user by the dotted local part of their email" do
    user = user_with_email("petr.tobiska@volny.cz")

    assert_includes Folio::User.by_query("petr.tobiska").pluck(:id), user.id
  end

  test "by_query still finds a user by their last name" do
    user = create(:folio_user, first_name: "Ľubomíra", last_name: "Kováčová")

    assert_includes Folio::User.by_query("kovacova").pluck(:id), user.id
  end

  test "by_query does not match unrelated users" do
    user_with_email("petr.tobiska@volny.cz")
    other = user_with_email("jan.weisser@example.com")

    assert_not_includes Folio::User.by_query("petr.tobiska@volny.cz").pluck(:id), other.id
  end

  # unaccent("ŉ") is "'n", and pg_search wraps every term in single quotes
  # before handing it to to_tsquery, so an unsanitized "ŉ" produces
  # `to_tsquery('simple', ''' ''n '':*')` and Postgres raises a syntax error.
  test "by_query folds a character that unaccent expands into an apostrophe" do
    user = create(:folio_user, first_name: nil, last_name: "ŉkolik")

    assert_includes Folio::User.by_query("ŉ").pluck(:id), user.id
  end

  test "by_query survives every configured special character" do
    Rails.application.config.folio_special_characters_character_string.each_char do |char|
      assert_kind_of Integer,
                     Folio::User.by_query(char).count,
                     "by_query failed for #{char.inspect} (U+#{format('%04X', char.ord)})"
    end
  end
end
