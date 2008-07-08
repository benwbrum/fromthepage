module ExtendActionController
  def self.included(base)
    base.alias_method_chain :process, :clientperf
  end
  
  def process_with_clientperf(request, response, *args, &block)
    result = process_without_clientperf(request, response, *args, &block)
    if add_clientperf?(request, response)
      add_clientperf_to(response)
    end
    result
  end
  
  def add_clientperf_to(response)
    if response.body =~ /(<html[^>]*?>).*(<\/html>)/im
      top = %q(\1
        <script type='text/javascript'>
          var _clientPerfStart = (new Date()).getTime();
        </script>
      )
      
      bottom = %q(
        <script type='text/javascript'>
        (function() {
        	function fn() { var end = (new Date()).getTime(), img = document.createElement('img'); img.height ='1'; img.width = '1'; img.src = '/clientperf/measure.gif?b='+_clientPerfStart+'&e='+end+'&u='+encodeURIComponent(location.href); document.body.appendChild(img); };
        	if (window.addEventListener) { window.addEventListener('load', fn, false); }
        	else if (window.attachEvent) { window.attachEvent('onload', fn); }
        	else { var chain = window.onload; window.onload = function(e) { if(chain !== undefined) { chain(e); } fn(); } }
        })();
        </script>
        </html>
      )
      
      response.body.sub!(/(<html[^>]*?>)/im, top)
      response.body.sub!(/<\/html>/im, bottom)
      
      response.headers["Content-Length"] = response.body.size
    end
  end
  
  def add_clientperf?(request, response)
    !request.xhr? && response.content_type && response.content_type.include?('html') && 
      response.body && response.headers['Status'] && response.headers['Status'].include?('200') && 
      controller_name != 'clientperf'
  end
end