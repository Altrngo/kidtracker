# config/initializers/rack_attack.rb
require "rack/attack"
#
# Protection contre le brute-force et les abus.
# Rack::Attack intercepte les requêtes AVANT qu'elles n'atteignent Rails.

class Rack::Attack
  ### Configuration du store ###
  # Utilise le cache Rails (memory_store en prod chez nous).
  # Note : avec memory_store, les compteurs sont par-processus.
  # Suffisant ici puisqu'on tourne en Puma single mode.
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Whitelist du réseau local ###
  # Les requêtes depuis le LAN ne sont jamais limitées.
  safelist("allow-local") do |req|
    req.ip.start_with?("192.168.", "10.", "172.16.", "127.0.0.1")
  end

  ### Limite générale par IP ###
  # 300 requêtes par 5 minutes — large pour un usage normal,
  # bloque le scraping agressif.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Tentatives de connexion par IP ###
  # 5 tentatives par 20 secondes sur le endpoint de login.
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  ### Tentatives de connexion par email ###
  # Empêche le "credential stuffing" distribué sur plusieurs IP
  # visant un même compte.
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalise l'email pour éviter le contournement par casse
      email = req.params.dig("user", "email").to_s.downcase.strip
      email.presence
    end
  end

  ### Blocage des scanners connus ###
  # Bloque les requêtes vers des chemins typiques de scan
  # (WordPress, phpMyAdmin, .env, etc.) — ces chemins n'existent
  # pas dans notre app, donc toute requête est malveillante.
  blocklist("block-scanners") do |req|
    req.path.match?(%r{
      ^/(wp-|wordpress|xmlrpc|phpmyadmin|admin\.php|\.env|\.git|
      vendor/phpunit|solr|cgi-bin|shell|config\.json)
    }xi)
  end

  ### Réponse personnalisée en cas de blocage ###
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    retry_after = match_data ? match_data[:period] : 60

    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After"  => retry_after.to_s
      },
      [ "Trop de requêtes. Réessayez dans #{retry_after} secondes.\n" ]
    ]
  end

  self.blocklisted_responder = lambda do |_request|
    [ 403, { "Content-Type" => "text/plain" }, [ "Forbidden\n" ] ]
  end
end

### Logging des blocages ###
# Trace les événements dans les logs Rails pour pouvoir auditer
# les tentatives d'intrusion.
ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, id, payload|
  req = payload[:request]
  next unless [ :throttle, :blocklist ].include?(req.env["rack.attack.match_type"])

  Rails.logger.warn(
    "[Rack::Attack] #{req.env['rack.attack.match_type']} " \
    "IP=#{req.ip} " \
    "path=#{req.path} " \
    "rule=#{req.env['rack.attack.matched']}"
  )
end
