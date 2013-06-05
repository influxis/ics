# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register "application/x-amf", :amf

module Mime
  class Type
    def split(*args)
      to_s.split(*args)
    end
  end
end