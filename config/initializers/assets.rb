# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Ensure builds directory takes precedence over stylesheets
Rails.application.config.assets.paths.unshift Rails.root.join("app/assets/builds")

# TailwindCSS configuration
Rails.application.config.assets.precompile += %w( application.css )