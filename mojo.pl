#!/usr/bin/env perl
use Mojolicious::Lite;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/with_layout';

get '/' => sub {
    my $self = shift;
    $self->render;
} => 'index';

get '/hello';

# Route with placeholder
get '/hello/:name' => sub {
    my $self = shift;
    my $name = $self->param('name');
    $self->render(text => "Hello world $name !");
};

get '/time' => 'clock';

# Scrape information from remote sites
post '/title' => sub {
    my $self  = shift;
    my $url   = $self->param('url') || 'http://mojolicio.us';
    my $title = $self->ua->get($url)->res->dom->at('title')->text;
    $self->render(json => {url => $url, title => $title});
};

get '/stash' => sub {
    my $self = shift;
    $self->stash(one => 23);
    $self->coucou("Coucou");
    $self->render('stash', two => 24);
};

# Access request information
get '/agent' => sub {
    my $self = shift;
    my $host = $self->req->url->to_abs->host;
    my $ua   = $self->req->headers->user_agent,;
    $self->render(text => "Request by $ua reached $host.");
};

# Echo the request body and send custom header with response
post '/echo' => sub {
    my $self = shift;
    $self->res->headers->header('X-Bender' => 'Bite my shiny metal ass!');
    $self->render(data => $self->req->body);
};

get '/with_block' => 'block';

# A helper to identify visitors
helper whois => sub {
    my $self  = shift;
    my $agent = $self->req->headers->user_agent || 'Anonymous';
    my $ip    = $self->tx->remote_address;
    return "$agent ($ip)";
};

# Use helper in action and template
get '/secret' => sub {
    my $self = shift;
    my $user = $self->whois;
    $self->app->log->debug("Request from $user");
};

# Home made helper for logging
# Make possible to log through $self->coucou('yé')
helper coucou => sub {
    my ($self, $token) = @_;
    $self->app->log->debug($token);
};


app->start;
__DATA__

@@ index.html.ep
% layout 'gray';
<p>We damn ♥  Mojolicious!</p>
<ul>
  <li><%= link_to Hello  => 'hello' %></li>
  <li><%= link_to Reload => 'index' %></li>
  <li><%= link_to Agent => 'agent' %></li>
  <li><%= link_to Stash => 'stash' %></li>
  <li><%= link_to Time => 'time' %></li>
  <li><%= link_to 'Placeholder Hello' => 'hello/smonff' %></li>
  <li><%= link_to 'Layouts' => 'with_layout' %></li>
  <li><%= link_to Blocks => 'with_block' %></li>
  <li><%= link_to 'Whois helper' => 'secret' %></li>
</ul>

@@ clock.html.ep
% use Time::Piece;
% my $now = localtime;
The time is <%= $now->hms %>

@@ stash.html.ep
The magic numbers are <%= $one %> and <%= $two %>.

@@ hello.html.ep
% layout 'gray';
Hello World!

@@ with_layout.html.ep
% title 'Gray';
% layout 'gray';
Hello template !

@@ layouts/gray.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <style>
      * { background-color: #DDD; }
    </style>
  </head>
  <body><%= content %></body>
</html>

@@ block.html.ep
% my $link = begin
  % my ($url, $name) = @_;
    Try <%= link_to $url => begin %><%= $name %><% end %>.
% end
% layout 'gray';
%= $link->('http://mojolicio.us', 'Mojolicious')
%= $link->('http://catalystframework.org', 'Catalyst')

@@ secret.html.ep
% layout 'gray';
We know how you are <code><%= whois %></code>
