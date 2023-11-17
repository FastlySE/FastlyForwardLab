sub vcl_recv {
#FASTLY recv

  # Normally, you should consider requests other than GET and HEAD to be uncacheable
  # (to this we add the special FASTLYPURGE method)
  if (req.method != "HEAD" && req.method != "GET" && req.method != "FASTLYPURGE") {
    return(pass);
  }

  # If you are using image optimization, insert the code to enable it here
  # See https://developer.fastly.com/reference/io/ for more information.
  return(lookup);



}

sub vcl_hash {
  set req.hash += req.url;
  set req.hash += req.http.host;
  #FASTLY hash
  return(hash);
}

sub vcl_hit {
#FASTLY hit
  return(deliver);
}

sub vcl_miss {
#FASTLY miss
  return(fetch);
}

sub vcl_pass {
#FASTLY pass
  return(pass);
}

sub vcl_fetch {
#FASTLY fetch

  # Unset headers that reduce cacheability for images processed using the Fastly image optimizer
  if (req.http.X-Fastly-Imageopto-Api) {
    unset beresp.http.Set-Cookie;
    unset beresp.http.Vary;
  }

  # Log the number of restarts for debugging purposes
  if (req.restarts > 0) {
    set beresp.http.Fastly-Restarts = req.restarts;
  }

  # If the response is setting a cookie, make sure it is not cached
  if (beresp.http.Set-Cookie) {
    return(pass);
  }

  # By default we set a TTL based on the `Cache-Control` header but we don't parse additional directives
  # like `private` and `no-store`. Private in particular should be respected at the edge:
  if (beresp.http.Cache-Control ~ "(?:private|no-store)") {
    return(pass);
  }

  # If no TTL has been provided in the response headers, set a default
  if (!beresp.http.Expires && !beresp.http.Surrogate-Control ~ "max-age" && !beresp.http.Cache-Control ~ "(?:s-maxage|max-age)") {
    set beresp.ttl = 3600s;

    # Apply a longer default TTL for images processed using Image Optimizer
    if (req.http.X-Fastly-Imageopto-Api) {
      set beresp.ttl = 2592000s; # 30 days
      set beresp.http.Cache-Control = "max-age=2592000, public";
    }
  }

if ( beresp.status == 406 ) {
      # ResponseObject: Block Page
      error 900 "Fastly Internal";
  }

  return(deliver);
}

sub vcl_error {
#FASTLY error

if (obj.status == 900 ) {
   set obj.http.Content-Type = "text/html";
   synthetic {" <!DOCTYPE html>
  <html lang="en">
  <head>
    <title>There was a problem</title>
    <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500" rel="stylesheet" type="text/css">
    <style>
      body { display: inline-block; background: #7000f9 no-repeat; height: 100vh; margin: 0; color: white; }
      h1 { margin: .8em 3rem; font: 4em Roboto; }
      p { display: inline-block; margin: .2em 3rem; font: 2em Roboto; }
    </style>
  </head>
  <body>
    <h1>Apologies, we have encountered an error!</h1>
    <p>We will work hard to resolve this issue</p>  
  </body>
  </html>"};
   return(deliver);
 }
}

sub vcl_deliver {
#FASTLY deliver
  return(deliver);
}

sub vcl_log {
#FASTLY log
}

