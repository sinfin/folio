# frozen_string_literal: true

class Folio::SpecialCharacters::ListComponent < Folio::SpecialCharacters::ApplicationComponent
  CHARACTER_STRING = (
    "\u00A0–…„\u201C\u201D\u201A\u2018'~^°±×÷%‰µ€§" \
    "ÃãĂăĀāĄąĆćĈĉĊċĐđ" \
    "ĖėĒēĘęĞğĢģĜĝĠġĤĥĦħ" \
    "ÎîÏïÌìİĪīĮįĨĩĲĳĴĵ" \
    "ĹĺĽľĻļĿŀŁłŃńŉŅņÑñ" \
    "ÓóÔôÖöÒòŐőŌōŒœØøÕõð" \
    "ÞþŔŕŖŗŚśŞşŜŝŢţŦŧ" \
    "ÛûÜüÙùŬŭŰűŪūŲųŨũ" \
    "ŴŵŸÿŶŷŹźŻż©®™"
  )

  def characters
    CHARACTER_STRING.grapheme_clusters
  end
end
