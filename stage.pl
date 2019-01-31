use warnings;
use strict;

use JSON;
use JSON::WebToken;
use LWP::UserAgent;
use HTML::Entities;
use File::Slurp;

# Client Specific info
my $STORAGE_NAME = "level3-8d8b789d9d480691b6115329da648c4982ef090d14a81f6306a6b79.neverlanctf.cloud";
my $ISS = "auto@neverlanctf.cloud";

# Storage upload url. Media name needs to be replaced.
my $STORAGE_URL="https://www.googleapis.com/upload/storage/v1/b/$STORAGE_NAME/o?uploadType=media&name=#{name}";

# file to be uploaded to bucket.
my $SAMPLE_FILE = "flag-8404a1cf41c933ccac002efe4d05f35b.html";

my $ua = LWP::UserAgent->new;

sub upload_via_lwp($$$) {
   my($token, $file, $url) = @_;

   my $data = read_file($file, { binmode => ':raw' });
   my $response = $ua->post(
      $url,
      "Authorization" => "Bearer $token",
      "Content_Type" => "text/html",
      "Content" => $data
   );

   # some error handling in real life...
   print $response->content();
}

sub upload_via_curl($$$) {
   my($token, $file, $url) = @_;

   my $cmd = "curl -X POST --data-binary @" . $file;
   $cmd .= " -H 'Authorization: Bearer $token'";
   $cmd .= " -H 'Content-Type: text/html'";
   $cmd .= " '$url'";

   my $result = `$cmd`;

   # some error handling in real life...
   print $result;
}

#
# OAuth2 & Authorization token
# https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatingjwt
#
my $time = time;
my $jwt = JSON::WebToken->encode({
      iss => $ISS,
      scope => "https://www.googleapis.com/auth/cloud-platform",
      aud => "https://accounts.google.com/o/oauth2/token",
      exp => $time + 600,
      iat => $time
   },
   "flag { ThisIsntAGoodPlaceToKeepAPrivateAccessKey } ", # PRIVATE KEY
   'RS256',
   {typ => 'JWT'}
);

my $response = $ua->post(
   'https://accounts.google.com/o/oauth2/token',
   {
      grant_type => encode_entities('urn:ietf:params:oauth:grant-type:jwt-bearer'),
      assertion => $jwt
   });

if ($response->is_success()) {
   my $data = decode_json($response->content);
   my $token = $data->{access_token};

   $STORAGE_URL =~ s/#{name}/flag-8404a1cf41c933ccac002efe4d05f35b.html/;

   upload_via_lwp($token, $SAMPLE_FILE, $STORAGE_URL);
   #upload_via_curl($token, $SAMPLE_FILE, $STORAGE_URL);
} else {
   print "Failed to get access token: " . $response->content();
}
