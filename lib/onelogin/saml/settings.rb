module Onelogin::Saml
  class Settings

    attr_accessor :assertion_consumer_service_url, :issuer, :sp_name_qualifier, :idp_sso_target_url,
      :idp_cert_fingerprint, :name_identifier_format, :idp_cert
  end
end