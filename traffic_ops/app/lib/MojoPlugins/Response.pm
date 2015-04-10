package MojoPlugins::Response;
#
# Copyright 2015 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
#

use Mojo::Base 'Mojolicious::Plugin';
use Carp qw(cluck confess);
use Data::Dumper;
use Hash::Merge qw( merge );

my $API_VERSION     = "1.1";
my $API_VERSION_KEY = "version";
my $ERROR_LEVEL     = "error";
my $INFO_LEVEL      = "info";
my $WARNING_LEVEL   = "warning";
my $SUCCESS_LEVEL   = "success";

my $ALERTS_KEY   = "alerts";
my $LEVEL_KEY    = "level";
my $TEXT_KEY     = "text";
my $STATUS_KEY   = "status";
my $JSON_KEY     = "json";
my $RESPONSE_KEY = "response";
my $LIMIT_KEY    = "limit";
my $ORDERBY_KEY  = "orderby";
my $PAGE_KEY     = "page";
my $INFO_KEY     = "supplemental";

sub register {
	my ( $self, $app, $conf ) = @_;

	# Success (200) - With a JSON response
	$app->renderer->add_helper(
		success => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");
			my $body = shift || confess("Please supply a response body hash.");

			# optional args
			my $orderby = shift;
			my $limit   = shift;
			my $page    = shift;

			my $response_body;
			if ( defined($limit) && defined($page) && defined($orderby) ) {
				$response_body =
					{ $API_VERSION_KEY => $API_VERSION, $RESPONSE_KEY => $body, $LIMIT_KEY => $limit, $PAGE_KEY => $page, $ORDERBY_KEY => $orderby };
			}
			elsif ( defined($limit) && defined($page) ) {
				$response_body = { $API_VERSION_KEY => $API_VERSION, $RESPONSE_KEY => $body, $LIMIT_KEY => $limit, $PAGE_KEY => $page };
			}
			elsif ( defined($limit) ) {
				$response_body = { $API_VERSION_KEY => $API_VERSION, $RESPONSE_KEY => $body, $LIMIT_KEY => $limit };
			}
			elsif ( defined($page) ) {
				$response_body = { $API_VERSION_KEY => $API_VERSION, $RESPONSE_KEY => $body, $PAGE_KEY => $limit };
			}
			else {
				$response_body = { $API_VERSION_KEY => $API_VERSION, $RESPONSE_KEY => $body };
			}
			return $self->render( $STATUS_KEY => 200, $JSON_KEY => $response_body );
		}
	);

	# Success (200) - a JSON message response
	$app->renderer->add_helper(
		success_message => sub {
			my $self           = shift || confess("Call on an instance of MojoPlugins::Response");
			my $alert_messages = shift || confess("Please supply a response message text string.");
			my $optional_extra = shift;

			my $response_body = { $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => [ { $LEVEL_KEY => $SUCCESS_LEVEL, $TEXT_KEY => $alert_messages } ] };
			if ( defined($optional_extra) ) {
				$response_body = {
					$API_VERSION_KEY => $API_VERSION,
					$ALERTS_KEY      => [ { $LEVEL_KEY => $SUCCESS_LEVEL, $TEXT_KEY => $alert_messages } ],
					$INFO_KEY        => $optional_extra
				};
			}
			return $self->render( $STATUS_KEY => 200, $JSON_KEY => $response_body );
		}
	);

	# No Content (204)
	$app->renderer->add_helper(
		no_content => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");

			my $response_body = { $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => [ { $LEVEL_KEY => $SUCCESS_LEVEL, $TEXT_KEY => "No Content" } ] };
			return $self->render( $STATUS_KEY => 204, $JSON_KEY => $response_body );
		}
	);

	# Alerts (400)
	$app->renderer->add_helper(
		alert => sub {
			my $self   = shift || confess("Call on an instance of MojoPlugins::Response");
			my $alerts = shift || confess("Please supply the alerts hash");

			my $builder ||= MojoPlugins::Response::Builder->new( $self, @_ );
			my @alerts_response = $builder->build_alerts($alerts);

			return $self->render( $STATUS_KEY => 400, $JSON_KEY => { $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => \@alerts_response } );
		}
	);

	# Alerts (500)
	$app->renderer->add_helper(
		internal_server_error => sub {
			my $self   = shift || confess("Call on an instance of MojoPlugins::Response");
			my $alerts = shift || confess("Please supply the alerts hash");

			my $builder ||= MojoPlugins::Response::Builder->new( $self, @_ );
			my @alerts_response = $builder->build_alerts($alerts);

			return $self->render( $STATUS_KEY => 500, $JSON_KEY => { $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => \@alerts_response } );
		}
	);

	# Alerts (500)
	$app->renderer->add_helper(
		internal_server_error => sub {
			my $self   = shift || confess("Call on an instance of MojoPlugins::Response");
			my $alerts = shift || confess("Please supply the alerts hash");

			my $builder ||= MojoPlugins::Response::Builder->new( $self, @_ );
			my @alerts_response = $builder->build_alerts($alerts);

			return $self->render( $STATUS_KEY => 500, $JSON_KEY => { $ALERTS_KEY => \@alerts_response } );
		}
	);

	# Unauthorized (401)
	$app->renderer->add_helper(
		unauthorized => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");

			my $response_body =
				{ $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => [ { $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => "Unauthorized, please log in." } ] };
			return $self->render( $STATUS_KEY => 401, $JSON_KEY => $response_body );
		}
	);

	# Invalid Username or Password (401)
	$app->renderer->add_helper(
		invalid_username_or_password => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");

			my $response_body =
				{ $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => [ { $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => "Invalid username or password." } ] };
			return $self->render( $STATUS_KEY => 401, $JSON_KEY => $response_body );
		}
	);

	# Invalid token (401)
	$app->renderer->add_helper(
		invalid_token => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");

			my $response_body = {
				$API_VERSION_KEY => $API_VERSION,
				$ALERTS_KEY      => [ { $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => "Invalid token. Please contact your administrator." } ]
			};
			return $self->render( $STATUS_KEY => 401, $JSON_KEY => $response_body );
		}
	);

	# Forbidden (403)
	$app->renderer->add_helper(
		forbidden => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");

			my $response_body = { $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => [ { $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => "Forbidden" } ] };
			return $self->render( $STATUS_KEY => 403, $JSON_KEY => $response_body );
		}
	);

	# Not Found (404)
	$app->renderer->add_helper(
		not_found => sub {
			my $self = shift || confess("Call on an instance of MojoPlugins::Response");

			my $response_body = { $API_VERSION_KEY => $API_VERSION, $ALERTS_KEY => [ { $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => "Resource not found." } ] };
			return $self->render( $STATUS_KEY => 404, $JSON_KEY => $response_body );
		}
	);

	# Deprecate will insert an 'info' message for old APIs
	$app->renderer->add_helper(
		deprecate => sub {
			my $self = shift;
			my $data = shift;

			# this parameter allows the ability to "append" to the info or "overwrite" keys from the defaults"
			my $info = shift;

			my $info_details = merge( $info, { deprecated => 'true', message => 'Expires in version 1.2', "api_doc" => '/api/1.1/docs' } );

			my @response = unshift( @$data, { info => $info_details } );

			return \@response;
		}
	);

}

package MojoPlugins::Response::Builder;

use Mojo::Base -strict;
use Scalar::Util;
use Carp ();
use Validate::Tiny;

sub new {
	my $class = shift;
	my ( $c, $object ) = @_;
	my $self = bless {
		c       => $c,
		object  => $object,
		checks  => [],
		filters => []
	}, $class;

	Scalar::Util::weaken $self->{c};
	$self;
}

# Build the Alerts response
sub build_alerts {
	my $self   = shift;
	my $result = shift;

	my @alerts;
	if ( ref($result) eq 'HASH' ) {
		my %response = %{$result};
		foreach my $msg_key ( keys %response ) {
			my %alert;
			if ( defined( $response{$msg_key} ) ) {
				my $alert_text = $msg_key . " " . $response{$msg_key};
				%alert = ( $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => $alert_text );
				push( @alerts, \%alert );
			}
		}
	}

	# If no key/value pair is passed just push out the error message as defined.
	else {
		my %alert = ( $LEVEL_KEY => $ERROR_LEVEL, $TEXT_KEY => $result );
		push( @alerts, \%alert );
	}
	return @alerts;
}

1;