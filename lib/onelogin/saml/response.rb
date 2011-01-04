module Onelogin::Saml
  class Response
    NAME_ID = "/samlp:Response/saml:Assertion/saml:Subject/saml:NameID"

    def initialize(response)
      @response = response
      @document = XMLSecurity::SignedDocument.new(Base64.decode64(@response))
    end
    
    def settings=(_settings)
      @settings = _settings
    end
    
    def is_valid?(x509_certificate)
      return false if @response.blank? || x509_certificate.blank?

      @document.validate_doc(x509_certificate) rescue false
    end

    def name_id
      @name_id ||= @document.elements[NAME_ID].text
    end
  end
end