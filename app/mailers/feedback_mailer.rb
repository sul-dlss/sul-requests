# frozen_string_literal: true

# FeedbackMailer
class FeedbackMailer < ApplicationMailer
  def submit_feedback(params, ip, host) # rubocop:disable Metrics/MethodLength
    @name = params[:name].presence || 'No name given'
    @email = params[:to].presence || 'No email given'
    @message = params[:message]
    @url = params[:url]
    @ip = ip
    @host = host
    @user_agent = params[:user_agent]
    @viewport = params[:viewport]

    mail(to: Settings.EMAIL_TO,
         subject: t('sul_requests.feedback_mailer.subject').to_s,
         from: 'feedback@requests.stanford.edu',
         reply_to: Settings.EMAIL_TO)
  end
end
