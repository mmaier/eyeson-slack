# notifies slack users
class SlackNotificationService
  include Rails.application.routes.url_helpers

  def initialize(access_token, channel)
    @slack_api = SlackApi.new(access_token)
    @channel   = channel
  end

  def start
    return if @channel.webinar_mode?
    if @channel.new_command?
      post_open_info
    else
      post_join_info
    end
  end

  def presentation(upload)
    return if @channel.thread_id.blank? || upload.nil?
    @slack_api.post_message!(channel:   @channel.external_id,
                             thread_ts: @channel.thread_id,
                             text:      upload['file']['permalink_public'])
  end

  def broadcast(url)
    message = @slack_api.post_message!(
      channel:     @channel.external_id,
      thread_ts:   @channel.thread_id,
      text:        url
    )
    return unless @channel.webinar_mode?
    @channel.thread_id = message['ts']
    @channel.save
  end

  private

  def post_open_info
    url  = meeting_url(id: @channel.external_id)
    text = I18n.t('.opened', url: url, scope: %i[meetings show])
    message = @slack_api.post_message!(
      channel:     @channel.external_id,
      text:        url,
      attachments: [{ color: '#9e206c', thumb_url: root_url + '/icon.png',
                      fallback: text, text: text }]
    )
    @channel.thread_id = message['ts']
    @channel.save
  end

  def post_join_info
    @slack_api.post_message!(
      channel:   @channel.external_id,
      thread_ts: @channel.thread_id,
      text:    I18n.t('.joined', scope: %i[meetings show])
    )
  end
end
