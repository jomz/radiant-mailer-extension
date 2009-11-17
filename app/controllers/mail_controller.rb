class MailController < ApplicationController

  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    @page = Page.find(params[:page_id])
    @page.request, @page.response = request, response

    config, part_page = config_and_page(@page)

    mail = Mail.new(part_page, config, params[:mailer])
    @page.last_mail = part_page.last_mail = mail
    process_mail(mail, config)

    if mail.send
      if !request.parameters[:mailer][:send_to_maillist].nil?
        # is mailbuild set up properly?
        if config.has_key? :mb_url
          # We get url's like http://gorilla.createsend.com/t/1/s/tlirt/
          # We post to url's like http://gorilla.createsend.com/t/1/s/tlirt/?mb-name=#{name}&mb-tlirt-tlirt=#{email}
          email_field = config[:mb_url].split('/').last
          data = request.parameters[:mailer]
          response.redirect("#{config[:mb_url]}?cm-name=#{data['naam']}&cm-#{email_field}-#{email_field}=#{data['email']}", "302 Found") and return
        else
          raise MailerTagError("Mailbuild is not properly set up.")
        end
      else
        redirect_to (config[:redirect_to] || "#{@page.url}#mail_sent")
      end
    else
      render :text => @page.render
    end
  end
  
  private
  
  # Hook here to do additional things, like check a CAPTCHA
  def process_mail(mail, config)
  end

  def config_and_page(page)
    until page.part(:mailer) or (not page.parent)
      page = page.parent
    end
    string = page.render_part(:mailer)
    [(string.empty? ? {} : YAML::load(string).symbolize_keys), page]
  end

end