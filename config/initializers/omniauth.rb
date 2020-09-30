Rails.application.config.middleware.use OmniAuth::Builder do
  if ENABLE_SAML then
    OmniAuth::MultiProvider.register(self,
                                     provider_name: :saml,
                                     identity_provider_id_regex: /\w+/, # TODO Possibly change this to LDS
                                     # path_prefix: '/auth/saml',
                                     path_prefix: '/users/auth/saml', # TODO Possibly remove LDS or /users/
                                     callback_suffix: 'callback',
                                     # Specify any additional provider specific options
                                     ) do |identity_provider_id, rack_env|
      options = {}
      if identity_provider_id == 'lds'
        options = {
          idp_cert: IDP_CERT,
          idp_sso_target_url: 'https://ident-uat.churchofjesuschrist.org/sso/SSORedirect/metaAlias/church/idp',
          issuer: 'https://fromthepage.com',
          attribute_statements: { 
            external_id: ['churchaccountid'], 
            email: ['workforceemail'], 
            email2: ['missionaryemail'], 
            name: ['preferredname'] 
          }
        }
      elsif identity_provider_id == 'samling'
        options = {
          idp_sso_target_url: 'https://capriza.github.io/samling/samling.html',
          idp_cert: 'MIICpzCCAhACCQDuFX0Db5iljDANBgkqhkiG9w0BAQsFADCBlzELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExEjAQBgNVBAcMCVBhbG8gQWx0bzEQMA4GA1UECgwHU2FtbGluZzEPMA0GA1UECwwGU2FsaW5nMRQwEgYDVQQDDAtjYXByaXphLmNvbTEmMCQGCSqGSIb3DQEJARYXZW5naW5lZXJpbmdAY2Fwcml6YS5jb20wHhcNMTgwNTE1MTgxMTEwWhcNMjgwNTEyMTgxMTEwWjCBlzELMAkGA1UEBhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExEjAQBgNVBAcMCVBhbG8gQWx0bzEQMA4GA1UECgwHU2FtbGluZzEPMA0GA1UECwwGU2FsaW5nMRQwEgYDVQQDDAtjYXByaXphLmNvbTEmMCQGCSqGSIb3DQEJARYXZW5naW5lZXJpbmdAY2Fwcml6YS5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAJEBNDJKH5nXr0hZKcSNIY1l4HeYLPBEKJLXyAnoFTdgGrvi40YyIx9lHh0LbDVWCgxJp21BmKll0CkgmeKidvGlr3FUwtETro44L+SgmjiJNbftvFxhNkgA26O2GDQuBoQwgSiagVadWXwJKkodH8tx4ojBPYK1pBO8fHf3wOnxAgMBAAEwDQYJKoZIhvcNAQELBQADgYEACIylhvh6T758hcZjAQJiV7rMRg+Omb68iJI4L9f0cyBcJENR+1LQNgUGyFDMm9Wm9o81CuIKBnfpEE2Jfcs76YVWRJy5xJ11GFKJJ5T0NEB7txbUQPoJOeNoE736lF5vYw6YKp8fJqPW0L2PLWe9qTn8hxpdnjo3k6r5gXyl8tk=',
        }
      end

      options
    end
  end
end
