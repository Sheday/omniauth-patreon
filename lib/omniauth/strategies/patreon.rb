require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Patreon < OmniAuth::Strategies::OAuth2

      DEFAULT_SCOPE = "identity".freeze

      option :name, 'patreon'

      option :client_options, {
        site: "https://www.patreon.com",
        authorize_url: "/oauth2/authorize",
        token_url: "/api/oauth2/token",
        auth_scheme: :request_body
      }

      option :access_token_options, {
        header_format: "Bearer %s",
        param_name: "access_token"
      }

      option :authorize_options, [:scope]

      def identity_url
        user_fields = "about,can_see_nsfw,created,email,first_name,full_name,hide_pledges,image_url,is_email_verified,last_name,like_count,social_connections,thumb_url,url,vanity"
        "https://www.patreon.com/api/oauth2/v2/identity?fields[user]=#{user_fields}&include=memberships"
      end

      def raw_info
        @raw_info ||= access_token.get(identity_url, parse: :json).parsed["data"]
      end

      credentials do
        hash = { "token" => access_token.token }
        if access_token.refresh_token
          hash["refresh_token"] = access_token.refresh_token
        end
        hash["expires_at"] = access_token.expires_at if access_token.expires?
        hash["expires"] = access_token.expires?
        hash
      end

      uid { raw_info["id"] }

      info do
        {
          email: raw_info["attributes"]["email"],
          name: raw_info["attributes"]["full_name"]
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def build_access_token
        super.tap do |token|
          token.options.merge!(access_token_options)
        end
      end

      def access_token_options
        options.access_token_options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
      end

      def callback_url
        return options[:redirect_uri] unless options[:redirect_uri].nil?
        full_host + script_name + callback_path
      end

      def authorize_params
        super.tap do |params|
          options[:authorize_options].each do |k|
            params[k] = request.params[k.to_s] unless [nil, ''].include?(request.params[k.to_s])
          end
          params[:scope] = params[:scope] || DEFAULT_SCOPE
        end
      end

    end
  end
end
