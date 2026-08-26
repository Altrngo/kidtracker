Rails.application.config.session_store :cookie_store,
  key: "_kidtracker_session",
  secure: Rails.env.production?,   # HTTPS uniquement
  httponly: true,                  # inaccessible en JavaScript
  same_site: :lax                  # protection CSRF supplémentaire
