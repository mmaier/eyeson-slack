# notifies slack users
class SlackNotificationService
  include Rails.application.routes.url_helpers

  def initialize(access_token, channel)
    @slack_api = SlackApi.new(access_token)
    @channel   = channel
  end

  def start
    return if @channel.webinar_mode?
    if @channel.thread_id.blank?
      post_open_info
    else
      post_join_info
    end
  end

  def presentation(upload)
    return if @channel.thread_id.blank? || upload.nil?
    @slack_api.post_message!(channel:   original_external_id,
                             thread_ts: @channel.thread_id,
                             text:      upload['file']['permalink_public'])
  end

  def broadcast_start(url)
    text = I18n.t('.broadcast_info', url: url, scope: %i[meetings show])
    message = @slack_api.post_message!(
      channel:     original_external_id,
      attachments: [{ color: '#9e206c', thumb_url: root_url + '/icon.png',
                      fallback: text, text: text }]
    )
    @channel.update thread_id: message['ts']

    attach_broadcast_url_to(url, message)
  end

  def broadcast_end
    @slack_api.post_message!(
      channel:   original_external_id,
      text:      I18n.t('.broadcast_end', scope: %i[meetings show]),
      thread_ts: @channel.thread_id
    )
  end

  def recording_uploaded(url)
    return if url.nil?
    @slack_api.post_message!(
      channel:   original_external_id,
      thread_ts: @channel.thread_id,
      text:      I18n.t('.recording_uploaded',
                        url: url,
                        scope: %i[meetings show])
    )
  end

  private

  def post_open_info
    url  = meeting_url(id: original_external_id)
    text = I18n.t('.opened', url: url, scope: %i[meetings show])
    message = @slack_api.post_message!(
      channel:     original_external_id,
      text:        url,
      attachments: [{ color: '#9e206c', thumb_url: root_url + '/icon.png',
                      fallback: text, text: text }]
    )
    @channel.update thread_id: message['ts']
  end

  def post_join_info
    @slack_api.post_message!(
      channel:   original_external_id,
      thread_ts: @channel.thread_id,
      text:      I18n.t('.joined', scope: %i[meetings show])
    )
  end

  def attach_broadcast_url_to(url, message)
    message = @slack_api.post_message!(
      channel:     original_external_id,
      thread_ts:   message['ts'],
      text:        I18n.t('.broadcast_url', url: url, scope: %i[meetings show])
    )
    @channel.update last_question_queued: message['ts']
  end

  def original_external_id
    @channel.external_id.gsub('_webinar', '')
  end
end
