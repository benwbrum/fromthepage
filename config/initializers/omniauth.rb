Rails.application.config.middleware.use OmniAuth::Builder do
  if ENABLE_SAML then
  	provider :saml,
        #idp_cert_fingerprint: 'B2:82:F9:21:7B:CF:D1:D0:9A:E8:4A:72:EC:54:43:9D:2A:D5:88:15:55:42:11:FD:3D:B0:79:C7:C9:CC:86:A3',
        idp_cert: IDP_CERT,
        #idp_sso_target_url: 'https://capriza.github.io/samling/samling.html'
        idp_sso_target_url: 'https://ident-uat.churchofjesuschrist.org/sso/SSORedirect/metaAlias/church/idp',
        issuer: 'https://fromthepage.com'
  end
end
