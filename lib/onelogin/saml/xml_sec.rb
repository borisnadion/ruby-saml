# The contents of this file are subject to the terms
# of the Common Development and Distribution License
# (the License). You may not use this file except in
# compliance with the License.
#
# You can obtain a copy of the License at
# https://opensso.dev.java.net/public/CDDLv1.0.html or
# opensso/legal/CDDLv1.0.txt
# See the License for the specific language governing
# permission and limitations under the License.
#
# When distributing Covered Code, include this CDDL
# Header Notice in each file and include the License file
# at opensso/legal/CDDLv1.0.txt.
# If applicable, add the following below the CDDL Header,
# with the fields enclosed by brackets [] replaced by
# your own identifying information:
# "Portions Copyrighted [year] [name of copyright owner]"
#
# $Id: xml_sec.rb,v 1.6 2007/10/24 00:28:41 todddd Exp $
#
# Copyright 2007 Sun Microsystems Inc. All Rights Reserved
# Portions Copyrighted 2007 Todd W Saxton.

require "base64"
require "rexml/document"
require "rexml/xpath"
require "openssl"
require "digest/sha1"
 
module XMLSecurity

  class SignedDocument < REXML::Document
    include REXML

    def self.cleanup_certificate(cert)
      cert.gsub("-----BEGIN CERTIFICATE-----", "").gsub("-----END CERTIFICATE-----", "").gsub("\r\n", "").gsub("\r", "").gsub("\n", "")
    end

    def validate_doc(x509_cert)
      base64_cert = SignedDocument.cleanup_certificate(x509_cert)

      # validate references
      
      # remove signature node
      sig_element = XPath.first(self, "//ds:Signature", {"ds"=>"http://www.w3.org/2000/09/xmldsig#"})
      sig_element.remove
      
      #check digests
      XPath.each(sig_element, "//ds:Reference", {"ds"=>"http://www.w3.org/2000/09/xmldsig#"}) do | ref |          
        
        uri                   = ref.attributes.get_attribute("URI").value
        hashed_element        = XPath.first(self, "//[@ID='#{uri[1,uri.size]}']")
        canoner               = XML::Util::XmlCanonicalizer.new(false, true)
        canon_hashed_element  = canoner.canonicalize(hashed_element)
        hash                  = Base64.encode64(Digest::SHA1.digest(canon_hashed_element)).chomp
        digest_value          = XPath.first(ref, "//ds:DigestValue", {"ds"=>"http://www.w3.org/2000/09/xmldsig#"}).text
        
        return false unless hash == digest_value
      end
 
      # verify signature
      canoner                 = XML::Util::XmlCanonicalizer.new(false, true)
      signed_info_element     = XPath.first(sig_element, "//ds:SignedInfo", {"ds"=>"http://www.w3.org/2000/09/xmldsig#"})
      canon_string            = canoner.canonicalize(signed_info_element)

      base64_signature        = XPath.first(sig_element, "//ds:SignatureValue", {"ds"=>"http://www.w3.org/2000/09/xmldsig#"}).text
      signature               = Base64.decode64(base64_signature)
      
      # get certificate object
      cert_text               = Base64.decode64(base64_cert)
      cert                    = OpenSSL::X509::Certificate.new(cert_text)
      
      valid_flag              = cert.public_key.verify(OpenSSL::Digest::SHA1.new, signature, canon_string)
        
      valid_flag
    end
   
  end
end
