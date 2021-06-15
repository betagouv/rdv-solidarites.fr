module IcsMultipartAttached
  attr_accessor :ics_payload

  def mail(*args)
    ics = ics_payload.present? ? IcalHelpers::Ics.from_payload(ics_payload) : nil

    # Sending icalendar events by email is complicated, buggy and unreliable. This is the result of various hacks.
    # * We add the icalendar twice to the email: once as a text/calendar part with a method, once as an attached .ics file.
    # * The method is always PUBLISH: we don’t want any replies.
    # There are other, historical tweaks that may not make sense:
    # * the attachment is using `encoding: "8bit"` to “fix encoding issues in ICS” (?)
    # * the text/calendar part is base64 encoded, although  “quoted-printable would be more adapted but there seems to be an encoding problem with extra =0D” (?)

    # Attachment
    if ics.present?
      message.attachments[ics_payload[:name]] = {
        mime_type: "text/calendar",
        content: ics,
        encoding: "8bit" # not sure why
      }
    end

    message = super

    # Separate part
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
