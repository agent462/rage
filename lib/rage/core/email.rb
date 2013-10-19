require 'mail'

module Rage
  class Email

    def send_email(message = {})
      Mail.defaults do
        delivery_method :smtp, {
          :address => 'smtp.gmail.com',
          :port => '587',
          :user_name => Config.email,
          :password => Config.email_password,
          :authentication => :plain,
          :enable_starttls_auto => true
        }
      end
      Mail.deliver do
         from    Config.email
         to      Config.email
         subject "Rage Trader: Recommendation #{message[:advice]}"
         body    message[:body]
      end
    end

  end
end