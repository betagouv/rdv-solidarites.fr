# frozen_string_literal: true

# adapted from https://github.com/rails/rails/blob/master/railties/lib/rails/mailers_controller.rb

module SuperAdmins
  class MailerPreviewsController < SuperAdmins::ApplicationController
    before_action :find_preview, only: :show
    around_action :with_locale, only: :show

    helper_method :part_query, :locale_query

    content_security_policy(false)

    def index
      @previews = ActionMailer::Preview.all
    end

    def show
      @email_action = File.basename(params[:id])
      raise AbstractController::ActionNotFound, "Email '#{@email_action}' not found in #{@preview.name}" unless @preview.email_exists?(@email_action)

      @page_title = "Mailer Preview for #{@preview.preview_name}##{@email_action}"
      @email = @preview.call(@email_action, params)

      if params[:part]
        part_type = Mime::Type.lookup(params[:part])

        if (part = find_part(part_type))
          response.content_type = part_type.to_s
          render(plain: part.respond_to?(:decoded) ? part.decoded : part)
          return
        end
        raise AbstractController::ActionNotFound, "Email part '#{part_type}' not found in #{@preview.name}##{@email_action}"
      else
        @part = find_preferred_part(request.format, Mime[:html], Mime[:text])
        render action: "email"
      end
    rescue ActiveRecord::RecordNotFound
      render plain: "could not find preview AR instance"
    end

    private

    # rubocop:disable all
    # this code is copied from rails source, so it feels ok not to lint it
    def find_preview
      candidates = []
      params[:id].to_s.scan(%r{/|$}) { candidates << $` }
      preview = candidates.detect { |candidate| ActionMailer::Preview.exists?(candidate) }

      return @preview = ActionMailer::Preview.find(preview) if preview

      raise AbstractController::ActionNotFound, "Mailer preview '#{params[:id]}' not found"
    end
    # rubocop:enable all

    def find_preferred_part(*formats)
      formats.each do |format|
        if (part = @email.find_first_mime_type(format))
          return part
        end
      end

      return @email if formats.any? { |f| @email.mime_type == f }
    end

    def find_part(format)
      if (part = @email.find_first_mime_type(format))
        part
      elsif @email.mime_type == format
        @email
      end
    end

    def part_query(mime_type)
      request.query_parameters.merge(part: mime_type).to_query
    end

    def locale_query(locale)
      request.query_parameters.merge(locale: locale).to_query
    end

    def with_locale(&block)
      I18n.with_locale(params[:locale] || I18n.default_locale, &block)
    end
  end
end
