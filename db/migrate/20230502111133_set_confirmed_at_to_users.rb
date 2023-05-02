# frozen_string_literal: true

class SetConfirmedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    unless reverting?
      if Rails.application.config.folio_users_confirm_email_change
        say_with_time "Setting confirmed_at to users" do
          Folio::User.where(confirmed_at: nil, unconfirmed_email: nil).update_all(confirmed_at: Time.current)
        end
      end
    end
  end
end
