use Test::More tests => 19;
use Text::Mint::Tokenizer;

my $t = Text::Mint::Tokenizer->new();
is($t, 1, 'rc 1 on ENOFILES');

my @list = qw(t/token_test1 t/token_test2);
$t = Text::Mint::Tokenizer->new( files => \@list );
is($t->{_filelist}->[0], 't/token_test1', '_filelist assignment');

my $tok = $t->next;
is($t->get_curfile, 't/token_test1', '_fopen');
is($tok, '[[x',                     'token read');
$tok = $t->next; is($tok, "a:'foo" ,'token read 2');
$tok = $t->next; is($tok, "bar']]" ,'token read 3');

$tok = $t->next; is($tok, '[[y'    ,'read across blank line');

$tok = $t->resend; is($tok, '[[y', 'repeat last token');

my($file,$line,$firstpart,$lastpart,$curtoken) = $t->stat;
is($file,      't/token_test1', 'stat 1');
is($line,      3,               'stat 2');
is($firstpart, '[[y ',          'stat 3');
is($lastpart,  " b:baz\n",      'stat 4');
is($curtoken,  '[[y',           'stat 5');

$t->next; 
$tok = $t->next;  is($tok, 'c:quux'          ,'line leading space');

$tok = $t->vnext; is($tok, "\n"              ,'verbatim read 1');
$tok = $t->vnext; is($tok, "           ]]\n" ,'verbatim read 2');

$tok = $t->vnext; is($tok, '[[x', 'seamless file changeover');

$tok = $t->vnext; is($tok, " a:'foo" ,'verbatim read 3');
$tok = $t->next; is($tok, "bar']]"  ,'token read 4');
