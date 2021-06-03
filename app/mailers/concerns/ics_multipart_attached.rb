module IcsMultipartAttached
  attr_accessor :ics_payload

  def mail(*args)
    ics = ics_payload.present? ? IcalHelpers::Ics.from_payload(ics_payload) : nil

    if ics.present?
      message.attachments[ics_payload[:name]] = { # as an attachment
        mime_type: "text/calendar",
        content: ics,
        encoding: "8bit" # not sure why
      }
    end

    message = super

    if ics.present?
      message.add_part( # and as a separate part
        Mail::Part.new do
          content_type "text/calendar; method=PUBLISH; charset=utf-8"
          body Base64.encode64(ics)
          content_transfer_encoding "base64"
        end
      )
    end

    message
  end
end
