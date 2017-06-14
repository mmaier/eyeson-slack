module CoolRenderer
  # Base Image
  class BaseImage
    def request(target, params)
      uri = URI("#{IMG_SERVICE}/#{target}")
      uri.user     = IMG_USER
      uri.password = IMG_PASSWD

      res = Net::HTTP.post_form uri, params
      JSON.parse(res.body)['link']
    rescue => e
      Rails.logger.error "Error occurred #{e.inspect}"
    end
  end
end
