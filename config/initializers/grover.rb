Grover.configure do |config|
  options = {
    format: 'A4',
    prefer_css_page_size: true,

    margin: {
      top: '1in',
      bottom: '1in',
      left: '1in',
      right: '1in'
    },

    emulate_media: 'print',
    cache: false,
    bypass_csp: true,

    wait_until: 'networkidle0',

    launch_args: [
      '--font-render-hinting=medium',
      '--disable-font-subpixel-positioning'
    ],

    user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36',

    scale: 0.75,
    viewport: {
      width: 1920,
      height: 1080
    },

    extra_http_headers: {
      'Accept-Language' => 'en-US'
    }
  }

  if ENV['CI'] == 'true'
    options[:launch_args] ||= []
    options[:launch_args] += [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu'
    ]
  end

  config.options = options
end
