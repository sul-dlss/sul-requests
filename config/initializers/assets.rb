# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths += [
  Rails.root.join('node_modules/bootstrap-sass/assets/javascripts'),
  Rails.root.join('node_modules/bootstrap-sass/assets/fonts')
]

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
%w(eot svg ttf woff woff2).each do |ext|
  Rails.application.config.assets.precompile << "bootstrap/glyphicons-halflings-regular.#{ext}"
end