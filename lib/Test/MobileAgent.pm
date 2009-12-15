package Test::MobileAgent;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.02';

our @EXPORT    = qw/test_mobile_agent/;
our @EXPORT_OK = qw/test_mobile_agent_env
                    test_mobile_agent_headers
                    test_mobile_agent_list/;
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

sub test_mobile_agent {
  my %env = test_mobile_agent_env(@_);

  $ENV{$_} = $env{$_} for keys %env;

  return %env if defined wantarray;
}

sub test_mobile_agent_env {
  my ($agent, %extra_headers) = @_;

  my ($vendor, $type) = _find_vendor($agent);
  my $class = _load_class($vendor);
  return $class->env($type, %extra_headers);
}

sub test_mobile_agent_headers {
  my %env = test_mobile_agent_env(@_);

  require HTTP::Headers::Fast;
  HTTP::Headers::Fast->new(%env);
}

sub test_mobile_agent_list {
  my ($vendor, $type) = _find_vendor(@_);
  my $class = _load_class($vendor);
  return $class->list($type);
}

sub _find_vendor {
  my $agent = shift;

  if ($agent =~ /^[a-z]+$/) {
    return (ucfirst($agent), '');
  }
  elsif ($agent =~ /^[a-z]+\./) {
    my ($vendor, $type) = split /\./, $agent;
    $vendor = ucfirst $vendor;
    return ($vendor, $type);
  }
  else {
    # do some guesswork
    my $vendor;
    if ($agent =~ /^DoCoMo/i) {
      return ('Docomo', $agent);
    }
    elsif ($agent =~ /^J\-PHONE/i) {
      return ('Jphone', $agent);
    }
    elsif ($agent =~ /^KDDI\-/i) {
      return ('Ezweb', $agent);
    }
    elsif ($agent =~ /^UP\.Browser/i) {
      return ('Ezweb', $agent);
    }
    elsif ($agent =~ /DDIPOCKET/i) {
      return ('Airh', $agent);
    }
    elsif ($agent =~ /WILLCOM/i) {
      return ('Airh', $agent);
    }
    elsif ($agent =~ /^Vodafone/i) {
      return ('Vodafone', $agent);
    }
    elsif ($agent =~ /^MOT/i) {
      return ('Vodafone', $agent);
    }
    elsif ($agent =~ /^Nokia/i) {
      return ('Vodafone', $agent);
    }
    elsif ($agent =~ /^SoftBank/i) {
      return ('Softbank', $agent);
    }
    else {
      return ('Nonmobile', $agent);
    }
  }
}

sub _load_class {
  my $vendor = shift;
  my $class = "Test::MobileAgent::$vendor";
  eval "require $class";
  if ($@) {
    $class = 'Test::MobileAgent::Nonmobile';
    require Test::MobileAgent::Nonmobile;
  }
  return $class;
}

1;

__END__

=head1 NAME

Test::MobileAgent - set environmental variables to mock HTTP::MobileAgent

=head1 SYNOPSIS

    use Test::More;
    use Test::MobileAgent;
    use HTTP::MobileAgent;

    # Case 1: you can simply pass a vendor name in lower case.
    {
      local %ENV;
      test_mobile_agent('docomo');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
    }

    # Case 2: also with some hint to be more specific.
    {
      local %ENV;
      test_mobile_agent('docomo.N503');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
    }

    # Case 3: you can pass a full name of an agent.
    {
      local %ENV;
      test_mobile_agent('DoCoMo/3.0/N503');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
    }

    # Case 4: you can also pass extra headers.
    {
      local %ENV;
      test_mobile_agent('DoCoMo/3.0/N503',
        x_dcmguid => 'STFUWSC',
      );

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
      ok $ua->user_id;   # STFUWSC
    }

    # Case 5: you need an HTTP::Headers compatible object?
    my $headers = test_mobile_agent_headers('docomo.N503');
    my $ua = HTTP::MobileAgent->new($headers);

    # Case 6: or just a hash of environmental variables?
    my %env = test_mobile_agent_env('docomo.N503');
    my $req = Plack::Request->new({ %plack_env, %env });

=head1 DESCRIPTION

This module helps to test applications that use L<HTTP::MobileAgent>. See the SYNOPSIS for usage.

=head1 METHODS

=head2 test_mobile_agent

=head2 test_mobile_agent_env

=head2 test_mobile_agent_headers

=head2 test_mobile_agent_list

=head1 TO DO

This can be a bit more powerful if you can pass something like an asset file of L<Moxy> to configure.

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<Moxy>

=head1 REPOSITORY

I am not a heavy user of mobile phones nor HTTP::MobileAgent. Patches are always welcome :)

L<http://github.com/charsbar/test-mobileagent>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
