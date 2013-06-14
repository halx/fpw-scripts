#
# Copyright (C) 2005-2011 Hannes Loeffler
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#
# Provides a simple markup interface for FreePWING
# (http://www.sra.co.jp/people/m-kasahr/freepwing/)
#
# That's my first module.  Probably clumsy, messy, etc... Use at your own risk.
# NOTE: details like tag or attribute names might change in future!
#



package FreePWING::FPWUtils::MarkupInterface;

require 5.005;			# have no clue what should be minimum version
require Exporter;
use FreePWING::FPWUtils::FPWParser;
use HTML::TokeParser;
use HTML::Entities;
use strict;
use warnings;

use vars qw(@ISA
            @EXPORT
            @EXPORT_OK
	    $VERSION
	    $fpwtext
	    $fpwheading
	    $fpwword2
	    $fpwkeyword
	    $fpwmenu
	    $fpwcopyright
	    $fpwobj
	    $tp
	    $hp);

$VERSION = 0.5.0;
@ISA = qw(Exporter);
@EXPORT_OK = qw(FreePWING_encode FreePWING_write);


# protect unsafe characters
sub FreePWING_encode {
  my $unsafe_chars;


  if (defined $_[1]) {
    $unsafe_chars = $_[1];
  } else {
    $unsafe_chars = '&<>"';
  }

  return encode_entities($_[0], $unsafe_chars);
}

# parse markup and trigger FreePWING functions accordingly
sub FreePWING_write {
  my $string = $_[0];

  my $parser = HTML::TokeParser->new(\$string);
  my ($ref_target, $graph_type, $type, $oldobj);


  while (my $token = $parser->get_token) {
    if ($token->[0] eq 'T') {
      $fpwobj->add_text(decode_entities($token->[1]))
	or _error($fpwobj, "$token->[1]");

      next;
    }

    if ($token->[0] eq 'S') {
      if ($token->[1] eq 'entry') {
	if (!defined $fpwtext) {
	  $fpwtext = FreePWING::FPWUtils::Text->new();
	  $fpwtext->open() or _error($fpwtext, "$token->[1]");
	}

	$fpwobj = $fpwtext;
	$fpwobj->new_entry() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'heading') {
	if (!defined $fpwheading) {
	  $fpwheading = FreePWING::FPWUtils::Heading->new();
	  $fpwheading->open() or die $fpwheading->error_message() . '\n';
	}

	# switch temporarily to fpwheading
	$oldobj = $fpwobj;
	$fpwobj = $fpwheading;
	$fpwobj->new_entry() or _error($fpwobj, "$token->[1]");

	$tp = $fpwtext->entry_position();
	$hp = $fpwheading->entry_position();
      } elsif ($token->[1] eq 'menu') {
	if (!defined $fpwmenu) {
	  $fpwmenu = FreePWING::FPWUtils::Menu->new();
	  $fpwmenu->open() or die _error($fpwmenu, "$token->[1]");
	}

	$fpwobj = $fpwmenu;
	$fpwobj->new_context() or die $fpwobj->error_message() . '\n';
      } elsif ($token->[1] eq 'copyright') {
	if (!defined $fpwcopyright) {
	  $fpwcopyright = FreePWING::FPWUtils::Copyright->new();
	  $fpwcopyright->open() or _error($fpwcopyright, "$token->[1]");
	}

	$fpwobj = $fpwcopyright;
	$fpwobj->new_context() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'context') {
	$fpwobj->new_context() or
	  _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'key') {
	if (defined $token->[2]{'type'}) {
	  if ($token->[2]{'type'} eq 'conditional') {
	    if (!defined $fpwkeyword) {
	      $fpwkeyword = FreePWING::FPWUtils::KeyWord->new();
	      $fpwkeyword->open() or
		_error($fpwkeyword, "$token->[1]($token->[2]{'type'})");
	    }

	    $fpwkeyword->add_entry($token->[2]{'name'}, $hp, $tp) or
	      _error($fpwkeyword, "$token->[1]($token->[2]{'type'}) = \"$token->[2]{'name'}\"");
	  }
	} else {
	  if (!defined $fpwword2) {
	    $fpwword2 = FreePWING::FPWUtils::Word2->new();
	    $fpwword2->open() or _error($fpwword2, "$token->[1]");
	  }

	  $fpwword2->add_entry($token->[2]{'name'}, $hp, $tp) or
	    _error($fpwword2, "$token->[1] = \"$token->[2]{'name'}\"");
	}
      } elsif ($token->[1] eq 'indent') {
	if (defined $token->[2]{'level'}) {
	  $fpwobj->add_indent_level($token->[2]{'level'}) or
	    _error($fpwobj, "$token->[1] = $token->[2]{'level'}");
	}
      } elsif ($token->[1] eq 'image') {
	$graph_type = '';
	
	if (defined $token->[2]{'name'}) {
	  $type = $token->[2]{'type'};

	  if (defined $type && $type eq 'jpeg') {
	    $fpwobj->add_jpeg_graphic_start($token->[2]{'name'}) or
	      _error($fpwobj, "$token->[1] = $token->[2]{'name'}, $type");

	    $graph_type = 'jpeg';
	  } else {
	    $fpwobj->add_color_graphic_start($token->[2]{'name'}) or
	      _error($fpwobj, "$token->[1] = $token->[2]{'name'}");
	  }
	}
      } elsif ($token->[1] eq 'sound') {
	if (defined $token->[2]{'name'}) {
	  $fpwobj->add_sound_start($token->[2]{'name'}) or
	    _error($fpwobj, "$token->[1] = $token->[2]{'name'}");
	}
      } elsif ($token->[1] eq 'gaiji') {
	if (defined $token->[2]{'type'}) {
	  if ($token->[2]{'type'} eq 'half') {
	    $fpwobj->add_half_user_character($token->[2]{'name'}) or
	      _error($fpwobj, "$token->[1]($token->[2]{'type'}) = $token->[2]{'name'}");
	  } elsif ($token->[2]{'type'} eq 'full') {
	    $fpwobj->add_full_user_character($token->[2]{'name'}) or
	      _error($fpwobj, "$token->[1]($token->[2]{'type'}) = $token->[2]{'name'}");
	  }
	}
      } elsif ($token->[1] eq 'tag') {
	if (defined $token->[2]{'name'}) {
	  $fpwobj->add_entry_tag($token->[2]{'name'}) or
	    _error($fpwobj, "$token->[1] = $token->[2]{'name'}");
	}
      } elsif ($token->[1] eq 'ref') {
	if (defined $token->[2]{'target'}) {
	  $fpwobj->add_reference_start() or
	    _error($fpwobj, "$token->[1] = $token->[2]{'target'}");
	  $ref_target = $token->[2]{'target'};
	}
      } elsif ($token->[1] eq 'keyword') {
	$fpwobj->add_keyword_start() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'nl') {
        $fpwobj->add_newline() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'b') {
	$fpwobj->add_font_start('bold') or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'i') {
	$fpwobj->add_font_start('italic') or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'em') {
	$fpwobj->add_emphasis_start() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'sub') {
	$fpwobj->add_subscript_start() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'super') {
	$fpwobj->add_superscript_start() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'nowrap') {
	$fpwobj->add_nowrap_start() or _error($fpwobj, "$token->[1]");
      } else {
	die 'Syntax error in markup: no such element <', $token->[1] . '>\n';
      }

      next;
    }

    if ($token->[0] eq 'E') {
      if ($token->[1] eq 'ref') {
	if (defined $ref_target) {
	  $fpwobj->add_reference_end($ref_target) or
	    _error($fpwobj, "$token->[1] = $ref_target");
	  undef $ref_target;
	}
      } elsif ($token->[1] eq 'heading') {
	$fpwobj = $oldobj;
      } elsif ($token->[1] eq 'image') {
	if ($graph_type eq 'jpeg') {
	  $fpwobj->add_jpeg_graphic_end() or _error($fpwobj, "$token->[1]");
	} else {
	  $fpwobj->add_color_graphic_end() or _error($fpwobj, "$token->[1]");
	}
      } elsif ($token->[1] eq 'sound') {
	$fpwobj->add_sound_end() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'keyword') {
	$fpwobj->add_keyword_end() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'b' or $token->[1] eq 'i') {
	$fpwobj->add_font_end() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'em') {
	$fpwobj->add_emphasis_end() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'sub') {
	$fpwobj->add_subscript_end() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'super') {
	$fpwobj->add_superscript_end() or _error($fpwobj, "$token->[1]");
      } elsif ($token->[1] eq 'nowrap') {
	$fpwobj->add_nowrap_end() or _error($fpwobj, "$token->[1]");
      } else {
	die 'Syntax error in markup: no such element <', $token->[1] . '>\n';
      }

      next;
    }
  }
}


sub _error {
  my $obj = shift;
  my $text = @_;

  print STDERR "  E> @_: ";
  die $obj->error_message() . '\n';
}


# cleanup
END {
  if (defined $fpwtext) {
    $fpwtext->close() or die $fpwtext->error_message() . '\n';
  }

  if (defined $fpwheading) {
    $fpwheading->close() or die $fpwheading->error_message() . '\n';
  }

  if (defined $fpwword2) {
    $fpwword2->close() or die $fpwword2->error_message() . '\n';
  }

  if (defined $fpwkeyword) {
    $fpwkeyword->close() or die $fpwkeyword->error_message() . '\n';
  }

  if (defined $fpwmenu) {
    $fpwmenu->close() or die $fpwmenu->error_message() . '\n';
  }

  if (defined $fpwcopyright) {
    $fpwcopyright->close() or die $fpwcopyright->error_message() . '\n';
  }
}

1;

__END__

=head1 NAME

FreePWING::FPWUtils::MarkupInterface - simple markup interface for FreePWING

=head1 SYNOPSIS

  use FreePWING::FPWUtils::MarkupInterface;

  FreePWING_write("<entry><heading>$item</heading>" .
                  "<key name=\"$kanji\"><key name=\"$kana\">" .
                  "<keyword>$kanji [$kana]</keyword><nl>".
                  "<indent level=\"2\">$content<nl>");

  # encode &, <, >, and " characters
  $string = FreePWING_encode($string);
  FreePWING_write($string);

=head1 DESCRIPTION

The C<FreePWING::FPWUtils::MarkupInterface> is an alternative interface to
C<FreePWING::FPWUtils::FPWParser>
(L<http://www.sra.co.jp/people/m-kasahr/freepwing/>).
This module controls the FreePWING parser via a simple markup language
(see L</MARKUP>).

The following functions are available:

=over 2

=item FreePWING_write($string);

Pass commands and data via markup tags (see L</MARKUP>) to trigger FreePWING
functions.

=item FreePWING_encode($string, $unsafe_chars);

Replace unsafe characters in $string with their entity representation.  The
characters &, <, >, and " are considered unsafe by default.  An optional second
argument string may be used to define ones own set of unsafe characters.
Returns encoded string.

=back

=head1 MARKUP

=over 2

=item <entry>

Creates a new dictionary entry.  B<Must> be followed by
C<E<lt>headingE<gt>$textE<lt>/headingE<gt>> where $text typically appears in
the hits field of an application.  C<E<lt>keywordE<gt>$textE<lt>/keywordE<gt>>
marks the head word of the actual entry. C<E<lt>key name="$key"E<gt>> is used
to indicate a search key.  The optional "conditional" attribute to
C<E<lt>keyE<gt>> may be used for conditional keys.

=item <menu>

Creates a new menu entry.

=item <copyright>

Creates a new copyright entry.

=item General markup

C<E<lt>entryE<gt>>, C<E<lt>menuE<gt>>, and C<E<lt>copyrightE<gt>> may be
followed by additional markup.  In the following (*) denotes markup which is
not allowed within C<E<lt>headingE<gt>E<lt>/headingE<gt>> and (+) denotes
markup which is not allowed within C<E<lt>keywordE<gt>E<lt>/keywordE<gt>>.

=item <tag name="$name"> and <ref $target="$name"> (*,+)

Add tag $name and refer to it.  Tags always belong to an entry as a whole.

=item <gaiji type="$type" name="$name">

Add gaiji character $name of type "half" or "full".  See FreePWING
documentation on HALFCHARS and FULLCHARS on how to associate names with actual
files.

=item <image name="$name" type="jpeg">$caption</image> (*)

Add image $name and optional $caption. An optional type attribute is also
accepted and the only value recognized is "jpeg" (if other value or not used
a BMP bitmap is expected). See FreePWING documentation on CGRAPHS on how to
associate names with actual files.

=item <sound name="$name">$caption</image> (*)

Add WAVE (PCM) sound data $name and optional $caption.  See FreePWING
documentation on SOUNDS on how to associate names with actual files.

=item <nl>

Create a newline.

=item <indent level="$level">

Indent the following line(s) by $level.

=item <b></b>, <i></i>, <em></em>, <sub></sub>, and <super></super>

Bold, italics, emphasized, subscripted and superscripted text.

=item <nowrap></nowrap>

Prevent wrapping of text.

=back

=head1 COPYRIGHT

Copyright 2005 Hannes Loeffler.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version.

=cut
