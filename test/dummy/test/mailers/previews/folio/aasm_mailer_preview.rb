# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/aasm_mailer
class Folio::AasmMailerPreview < ActionMailer::Preview
  def event
    Folio::AasmMailer.event("test@test.test",
                            "test subject",
                            "text content\n\nwith new lines")
  end
end
