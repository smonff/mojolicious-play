#!/usr/bin/env perl
use Mojolicious::Lite;


my $ascii_art = qq {
     __     __  ___         _        __ _       _                   __  
    / /    /  |/  /___     (_)___   / /(_)____ (_)___  __ __ ___    \\ \\ 
   < <    / /|_/ // _ \\   / // _ \\ / // // __// // _ \\/ // /(_-<     > >
    \\_\\  /_/  /_/ \\___/__/ / \\___//_//_/ \\__//_/ \\___/\\_,_//___/    /_/ 
                      |___/                                             
};

# Documentation browser under "/perldoc"
plugin 'PODRenderer';
say $ascii_art;

my $log = Mojo::Log->new;

# Code shared by all routes
under sub {
    my $self = shift;

    $self->stash(mojo => $ascii_art);
    $log->debug("Mojo Art defined");
    return 1;
};

get '/with_layout';

get '/' => sub {
    my $self = shift;
    $self->render;
} => 'index';

# Find the right template automatically
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

    $log->debug("C'est du debug " . $self->stash->{one});
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
    $log->debug("Request from $user");
};

# /placeholder/foo
# /placeholder/foooo
get '/placeholder/:anything' => sub {
    my $self = shift;
    my $any  = $self->stash('anything');
    $log->debug("Our :anything placeholder matched $any");
    $self->render(text => "Our <code>:anything</code> placeholder matched <code>$any</code>");
};

# /foo/placeholder
# /fooooo/placeholder
get '/(:anything)/placeholder' => sub {
    my $self = shift;
    my $any = $self->param('anything');
    $self->render(text => "Our <code>:anything</code> placeholder matched <code>$any</code>");
};

# /foo/hello
# /fooo/hello
# /fooo.123/hello
get '/#you/hello' => 'groovy';

# Matches everything including '/' and '..'
# It means you can "cd ../"
get '/everything/*you' => 'groovyverything';

# PUT /hello
put '/put/:something' => sub {
    my $self = shift;
    my $size = length $self->req->body;
    $self->render(text => "You uploaded <code>$size</code> bites to <code>/put/hello</code>");
};

# HTTP method
# * /whatever
any '/whatever' => sub {
    my $self = shift;
    my $method = $self->req->method;
    $self->render(text => "You called <code>/whatever</code> with <code>$method</code>");
};

# Optionnal placeholder
# /optional
# /optional/placeholder
get '/optional/:placeholder' => {name => ' Sebastian ', day => 'Monday'} =>
sub {
    my $self = shift;
    $self->render('optional', format => 'txt');
};

# Restrictive placeholder
# only matches /restrictive/test /restrictive/lala and /restrictive/123
any '/restrictive/:foo' => [foo => [qw(test lala 123)]] => sub {
    my $self = shift;
    my $foo = $self->param('foo');
    $self->render(text => "Our :foo placeholder matched $foo");
};

# Restrictive placeholder are very powerful with regexes
# only matches /restrictive/1 /restrictive/123 and etc.
any '/restrictive/regex/:foo' => [foo => qr/\d+/] => sub {
    my $self = shift;
    my $foo = $self->param('foo');
    $log->debug("$foo captured");
    $self->render(text => "Our :foo placeholder matched $foo");
};

get 'detection' => sub {
    my $self = shift;
    $self->render('detected');
};

get 'content/negociation' => sub {
    my $self = shift;
    $self->respond_to(
	json => {
	    json => {
		mojo => {
		    hello => 'world',
		    loved_frameworks => {
			'Mojolicious' => '4.91',
			'Catalyst' => '',
		    }
		}
	    }
	},
	xml  => {text => '<mojo><hello>world</hello></mojo>'}
    );
};

app->start;

__DATA__

@@ index.html.ep
% layout 'gray';
<p>
  We damn ♥  Mojolicious!  
  This is ready-made examples of 
  <%= link_to 'Mojolicious::Lite' => 'perldoc/Mojolicious/Lite' %> tutorial.
</p>
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
  <li><%= link_to 'Placeholders' => 'placeholder' %></li>
  <li><%= link_to 'Another placeholders' => 'another/placeholder' %></li>
  <li><%= link_to 'Relaxed placeholders' => 'smonff/hello' %></li>
  <li><%= link_to 'Wilcard placeholders' => 'everything/smonff' %></li>
  <li><%= link_to 'Whatever method' => 'whatever' %></li>
  <li><%= link_to 'Optional placeholder' => 'optional/smonff' %></li>
  <li>
    Extension detection :
    <%= link_to 'html' => 'detection.html' %>
    <%= link_to 'txt' => 'detection.txt' %>
    <%= link_to 'json' => 'detection.json' %>
  </li>
  <li>
    Content negociation :
    <%= link_to 'xml' => 'content/negociation.xml' %>
    <%= link_to 'json' => 'content/negociation.json' %>
  </li>
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
% # Would like to make an only declaration, we actually have both
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <style>
      html {
	border: 1em solid #AAA;
	background-color: #DDD;
	padding: 10px;
	height: 100%;
      }
    </style>
  </head>
  <body>
    <%= content %>
    <footer>
      <pre><%= $mojo %></pre>
    </footer>
  </body>
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
We know how you are <pre><%= whois %></pre>

@@ groovy.html.ep
% layout 'gray';
Your name is <%= $you %>

@@ groovyverything.html.ep
% layout 'gray';
<p>Your name is <%= $you %></p>
<p>
  Try to go to <a href="/everything/../"><code>/everything/../</code></a>
  (just like in a <code>cd</code>)
</p>

@@ optional.txt.ep
My name is  <%= $name =%> and it is <%= $day %> using placeholder <%= " $placeholder" =%>

@@ detected.html.ep
% layout 'gray';
<code>HTML</code> was <strong>detected</strong> !!!

@@ detected.txt.ep
% layout 'gray';
TXT was detected

@@ detected.json.ep
{
    "json": {
	"detected": true
    }
}
