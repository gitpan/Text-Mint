package Text::Mint::Tokenizer;

# $Id: Tokenizer.pm 25 2004-11-24 18:59:16Z mdxi $

use warnings;
use strict;
use vars '$AUTOLOAD';

=head1 NAME

Text::Mint::Tokenizer - Turn files into a stream of tokens

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This module was written as part of L<Text::Mint> and is meant to be
used from within it, but for anyone desiring to use it as a
general-purpose tokenizer:

    use Text::Mint::Tokenizer;

    my $t = Text::Mint::Tokenizer->new( files => \@filelist );

    # fetch a single token
    my $token = $t->next;
    # fetch a token in verbatim mode
    $token = $t->vnext;
    # send last parsed token again
    $lasttoken = $t->resend;

    # the lexxer has thrown an error. get file info for diagnostic
    # message to user
    my ($file,$linenum,$firstpart,$lastpart,$token) = $t->stat;

T::M::T doesn't perform any kind of lexical analysis; it is strictly a
tokenizer. Its definitions of "token" are not configurable. It does,
however, have nifty transparent filehandling capabilities and two ways
of thinking about "a token" to facilitate text-processing needs.

When the end of the token stream is reached, C<undef> will be returned
by a call to C<next> or C<vnext>.

=head1 METHODS

=head2 new

Create a new Tokenizer object. The only argument to C<new> is an
arrayref containing the names of files to be tokenized. If this
argument is omitted, the call to C<new> will return a value of 1
(indicating failure) instead of an object.

=cut

sub new {
    my $class = shift; shift;
    my $files = shift;

    return 1 if (!defined $files->[0]); # ENOFILES

    my $self = bless { _filelist  => $files,
                       _curfile   => 0,
                       _curline   => '',
                       _firstpart => '',
                       _token     => '',
                     }, $class;
    return $self;
}

=head2 next

The usual way of getting a token. Returns the next token from the
present file, where "token" is defined as "string of contiguous
nonwhitespace characters". Returns C<undef> if a token cannot be read
(usually when the end of the last input file has been reached).

=cut

sub next {
    my $self = shift;
    my $line = $self->get_curline;

    until ($line ne '' and $line !~ /^\s*\n$/) {
        my $rc = $self->_lf;
        return undef if $rc;
        $line = $self->get_curline;
    }

    $line =~ s/^\s+//;
    $line =~ /^(\S+)/;
    $self->set_token($1);
    $self->{_firstpart} .= "$1 ";
    $line =~ s/^\S+//;
    $self->set_curline($line);

    return $self->get_token;
}

=head2 vnext

Works like C<next> but considers leading whitespace and/or a trailing
newline to be part of the token. This is called when the lexxer is
inside a verbatim text trigger or quoted string. Returns C<undef> if a
token cannot be read (usually when the end of the last input file has
been reached).

=cut

sub vnext {
    my $self = shift;
    my $line = $self->get_curline;

    if ($line eq '') {
        my $rc = $self->_lf;
        return undef if $rc;
        $line = $self->get_curline;
    }

    $line =~ /^(\s*\S*\n?)/;
    $self->set_token($1);
    $self->{_firstpart} .= "$1 ";
    $line =~ s/^\s*\S*\n?//;
    $self->set_curline($line);

    return $self->get_token;
}

=head2 resend

Returns the previously-parsed (current) token.

=cut

sub resend {
    my $self = shift;
    return $self->get_token;
}

=head2 stat

Returns the name of the current open file, the number of the last line
read from that file, the current line fragment up to the last token,
the current line fragment following the last token, and the last token
parsed from the current line.

=cut

sub stat {
    my $self = shift;
    return ($self->get_curfile,
            $.,
            $self->get_firstpart,
            $self->get_curline,
            $self->get_token,
           );
}

=head1 INTERNAL METHODS

=head2 _lf

Internal use only. Fetches next line of input. Returns zero on
success, nonzero on failure.

=cut

sub _lf {
    my $self = shift;
    my $line = '';

    $self->set_firstpart('');
    $line= <FH> if $self->get_curfile;
    if (!defined $line or $line eq '' or !$self->get_curfile) {
        my $rc = $self->_fopen;
        return $rc if $rc; 
        $line = <FH>;
    }
    $self->set_curline($line);

    return 0;
}

=head2 _fopen

Internal use only. Opens the next input file. Returns zero on success,
nonzero on failure.

=cut

sub _fopen {
    my $self = shift;

    $self->set_curfile(shift @{$self->{_filelist}});
    return 2 unless (-r $self->get_curfile);

    close FH;
    open FH,'<',$self->get_curfile;

    return 0;
}

=head1 AUTHOR

Shawn Boyette, C<< <mdxi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Shawn Boyette, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub Text::Mint::Tokenizer::AUTOLOAD {
    no strict "refs";
    my ($self, $newval) = @_;
    if ($AUTOLOAD =~ /.*::get(_\w+)/) {
        my $attr = $1;
        *{$AUTOLOAD} = sub { return $_[0]->{$attr} };
        return $self->{$attr};
    }
    if ($AUTOLOAD =~ /.*::set(_\w+)/) {
        my $attr = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr} = $_[1]; return };
        $self->{$attr} = $newval;
        return;
    }
}

1; # End of Text::Mint::Tokenize
