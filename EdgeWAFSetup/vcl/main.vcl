sub vcl_fetch {
if ( beresp.status == 406 ) {
      # ResponseObject: Block Page
      error 900 "Fastly Internal";
  }
}

sub vcl_error {
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


