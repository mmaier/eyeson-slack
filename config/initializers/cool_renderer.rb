# Cool Renderer bootstrap.

require Rails.root.join 'lib', 'cool_renderer'

module CoolRenderer
  IMG_SERVICE = Rails.configuration.services['image_service']
  IMG_USER    = Rails.application.secrets[:img_service]['user']
  IMG_PASSWD  = Rails.application.secrets[:img_service]['password']
end
