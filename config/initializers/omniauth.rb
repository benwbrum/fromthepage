Rails.application.config.middleware.use OmniAuth::Builder do
  if ENABLE_SAML then
  	provider :saml,
        idp_cert: IDP_CERT,
        idp_sso_target_url: 'https://ident-uat.churchofjesuschrist.org/sso/SSORedirect/metaAlias/church/idp',
        issuer: 'https://fromthepage.com',
        attribute_statements: { 
          external_ld: ['churchaccountid'], 
          email: ['workforceemail'], 
          email2: ['missionaryemail'], 
          name: ['preferredname'] 
        }
  end
end
