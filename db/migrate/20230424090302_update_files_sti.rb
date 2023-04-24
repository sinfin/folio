# frozen_string_literal: true

class UpdateFilesSti < ActiveRecord::Migration[7.0]
  def change
    if reverting?
      say_with_time "reverting folio files STI to not use the file namespace" do
        Folio::File.where(type: "Folio::File::Document").update_all(type: "Folio::Document")
        Folio::File.where(type: "Folio::File::Image").update_all(type: "Folio::Image")
      end
    else
      say_with_time "updating folio files STI to use the file namespace" do
        Folio::File.where(type: "Folio::Document").update_all(type: "Folio::File::Document")
        Folio::File.where(type: "Folio::Image").update_all(type: "Folio::File::Image")
      end
    end
  end
end
