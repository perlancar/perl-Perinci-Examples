package Perinci::Examples;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use List::Util qw(min max);
use Perinci::Object;
use Perinci::Sub::Util qw(gen_modified_sub);
use Scalar::Util qw(looks_like_number);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       delay dies err randlog
                       gen_array gen_hash
                       noop
               );
our %SPEC;

# package metadata
$SPEC{':package'} = {
    v => 1.1,
    summary => 'Various examples of Rinci metadata',
    "summary.alt.lang.id_ID" => 'Berbagai contoh metadata Rinci',
    description => <<'_',

A sample description

    verbatim
    line2

Another paragraph with *bold*, _italic_ text.

_
};

# variable metadata
$SPEC{'$Var1'} = {
    v => 1.1,
    summary => 'This variable contains the meaning of life',
    description => <<'_',

Currently Riap is very function-centric and other code entities like variables
are not that well-supported. The action `get` will get the value for a variable,
but this is not supported by all Riap clients, because someRiap clients only
focus on calling functions.

_
};
our $Var1 = 42;

# as well as testing default_lang and *.alt.lang.XX properties
$SPEC{delay} = {
    v => 1.1,
    default_lang => 'id_ID',
    "summary.alt.lang.en_US" => "Sleep, by default for 10 seconds",
    "description.alt.lang.en_US" => <<'_',

Can be used to test the *time_limit* property.

_
    summary => "Tidur, defaultnya 10 detik",
    description => <<'_',

Dapat dipakai untuk menguji properti *time_limit*.

_
    args => {
        n => {
            default_lang => 'en_US',
            summary => 'Number of seconds to sleep',
            "summary.alt.lang.id_ID" => 'Jumlah detik',
            schema => ['int', {default=>10, min=>0, max=>7200}],
            pos => 0,
        },
        per_second => {
            "summary.alt.lang.en_US" => 'Whether to sleep(1) for n times instead of sleep(n)',
            summary => 'Jika diset ya, lakukan sleep(1) n kali, bukan sleep(n)',
            schema => ['bool', {default=>0}],
        },
    },
};
sub delay {
    my %args = @_; # NO_VALIDATE_ARGS
    my $n = $args{n} // 10;

    if ($args{per_second}) {
        sleep 1 for 1..$n;
    } else {
        sleep $n;
    }
    [200, "OK", "Slept for $n sec(s)"];
}

$SPEC{dies} = {
    v => 1.1,
    summary => "Dies tragically",
    description => <<'_',

Can be used to test exception handling.

_
    args => {
    },
};
sub dies {
    my %args = @_;
    die;
}

$SPEC{err} = {
    v => 1.1,
    summary => "Return error response",
    description => <<'_',


_
    args => {
        code => {
            summary => 'Error code to return',
            schema => ['int' => {default => 500}],
            pos => 0,
        },
    },
};
sub err {
    my %args = @_; # NO_VALIDATE_ARGS
    my $code = int($args{code}) // 0;
    $code = 500 if $code < 100 || $code > 555;
    [$code, "Response $code"];
}

my %str_levels = qw(1 fatal 2 error 3 warn 4 info 5 debug 6 trace);
$SPEC{randlog} = {
    v => 1.1,
    summary => "Produce some random Log::Any log messages",
    description => <<'_',

_
    args => {
        n => {
            summary => 'Number of log messages to produce',
            schema => [int => {default => 10, min => 0, max => 1000}],
            pos => 0,
        },
        min_level => {
            summary => 'Minimum level',
            schema => ['int*' => {default=>1, min=>0, max=>6}],
            pos => 1,
        },
        max_level => {
            summary => 'Maximum level',
            schema => ['int*' => {default=>6, min=>0, max=>6}],
            pos => 2,
        },
    },
};
sub randlog {
    my %args      = @_; # NO_VALIDATE_ARGS
    my $n         = $args{n} // 10;
    $n = 1000 if $n > 1000;
    my $min_level = $args{min_level};
    $min_level = 1 if !defined($min_level) || $min_level < 0;
    my $max_level = $args{max_level};
    $max_level = 6 if !defined($max_level) || $max_level > 6;

    for my $i (1..$n) {
        my $num_level = int($min_level + rand()*($max_level-$min_level+1));
        my $str_level = $str_levels{$num_level};
        $log->$str_level("($i/$n) This is random log message #$i, ".
                             "level=$num_level ($str_level): ".
                                 int(rand()*9000+1000));
    }
    [200, "OK", "$n log message(s) produced"];
}

gen_modified_sub(
    output_name  => 'call_randlog',
    base_name    => 'randlog',
    summary      => 'Call randlog()',
    description  => <<'_',

This is to test nested call (e.g. Log::Any::For::Package).

_
    output_code => sub {
        # SUB: call_randlog
        # NO_VALIDATE_ARGS
        randlog(@_);
    },
);

$SPEC{gen_array} = {
    v => 1.1,
    summary => "Generate an array of specified length",
    description => <<'_',

Also tests result schema.

_
    args => {
        len => {
            summary => 'Array length',
            schema => ['int' => {default=>10, min => 0, max => 1000}],
            pos => 0,
            req => 1,
        },
    },
    result => {
        schema => ['array*', of => 'int*'],
    },
};
sub gen_array {
    my %args = @_; # NO_VALIDATE_ARGS
    my $len = int($args{len});
    defined($len) or return [400, "Please specify len"];
    $len = 1000 if $len > 1000;

    my $array = [];
    for (1..$len) {
        push @$array, int(rand()*$len)+1;
    }
    [200, "OK", $array];
}

gen_modified_sub(
    output_name  => 'call_gen_array',
    base_name    => 'gen_array',
    summary      => 'Call gen_array()',
    description  => <<'_',

This is to test nested call (e.g. Log::Any::For::Package).

_
    output_code  => sub {
        # SUB: call_gen_array
        # NO_VALIDATE_ARGS
        gen_array(@_);
    },
);

$SPEC{gen_hash} = {
    v => 1.1,
    summary => "Generate a hash with specified number of pairs",
    description => <<'_',

Also tests result schema.

_
    args => {
        pairs => {
            summary => 'Number of pairs',
            schema => ['int*' => {min => 0, max => 1000}],
            default => 10,
            pos => 0,
        },
    },
    result => {
        schema => ['array*', of => 'int*'],
    },
};
sub gen_hash {
    my %args = @_; # NO_VALIDATE_ARGS
    my $pairs = int($args{pairs});
    defined($pairs) or return [400, "Please specify pairs"];
    $pairs = 1000 if $pairs > 1000;

    my $hash = {};
    for (1..$pairs) {
        $hash->{$_} = int(rand()*$pairs)+1;
    }
    [200, "OK", $hash];
}

$SPEC{noop} = {
    v => 1.1,
    summary => "Do nothing, return original argument",
    description => <<'_',

Will also return argument passed to it.

This function is also marked as `pure`, meaning it will not cause any side
effects. Pure functions are safe to call directly in a transaction (without
going through the transaction manager) or during dry-run mode.

_
    args => {
        arg => {
            summary => 'Argument',
            schema => ['any'],
            pos => 0,
        },
    },
    features => {pure => 1},
};

sub noop {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", $args{arg}];
}

$SPEC{test_completion} = {
    v => 1.1,
    summary => "Do nothing, return args",
    description => <<'_',

This function is used to test argument completion.

_
    args => {
        arg0 => {
            summary => 'Argument without any schema',
            description => <<'_',
_
        },
        i0 => {
            summary => 'Integer with just "int" schema defined',
            schema  => ['int*'],
            description => <<'_',
_
        },
        i1 => {
            summary => 'Integer with min/xmax on the schema',
            schema  => ['int*' => {min=>1, xmax=>100}],
            pos => 0,
            description => <<'_',

A completion library (like `Perinci::Sub::Complete`) can generate a list of
completion from the low end to the high end of the range, as long as it is not
too long.

_
        },
        i2 => {
            summary => 'Integer with large range min/max on the schema',
            schema  => ['int*' => {min=>1, max=>1000}],
            description => <<'_',

Unlike in `i1`, a completion library probably won't generate a number sequence
for this argument because they are considered too long (1000+ items).

_
        },
        f0 => {
            summary => 'Float with just "float" schema defined',
            schema  => ['float*'],
        },
        f1 => {
            summary => 'Float with xmin/xmax on the schema',
            schema => ['float*' => {xmin=>1, xmax=>10}],
            description => <<'_',

A completion library can attempt to provide some possible and incremental
completion (e.g. if word is currently at one decimal digit like 1.2, it can
provide completion of 1.20 .. 1.29).

_
        },
        s1 => {
            summary => 'String with possible values in "in" schema clause',
            schema  => [str => {
                in  => [qw/apple apricot banana grape grapefruit/,
                        "red date", "red grape", "green grape",
                    ],
            }],
        },
        s1b => {
            summary => 'String with possible values in "in" schema clause, contains special characters',
            description => <<'_',

This argument is intended to test how special characters are escaped.

_
            schema  => [str => {
                in  => [
                    "space: ",
                    "word containing spaces",
                    "single-quote: '",
                    'double-quote: "',
                    'slash/',
                    'back\\slash',
                    "tab\t",
                    "word:with:colon",
                    "dollar \$sign",
                    "various parenthesis: [ ] { } ( )",
                    "tilde ~",
                    'backtick `',
                    'caret^',
                    'at@',
                    'pound#',
                    'percent%',
                    'ampersand&',
                    'question?',
                    'wildcard*',
                    'comma,',
                    'semicolon;',
                    'pipe|',
                    'redirection > <',
                    'plus+',
                ],
            }],
        },
        s2 => {
            summary => 'String with completion routine that generate random letter',
            schema  => 'str',
            completion => sub {
                my %args = @_;
                my $word = $args{word} // "";
                [ map {$word . $_} "a".."z" ],
            },
        },
        s3 => {
            summary => 'String with completion routine that dies',
            schema  => 'str',
            completion => sub { die },
            description => <<'_',

Completion should not display error (except perhaps under debugging). It should
just provide no completion.

_
        },
        a1 => {
            summary => 'Array of strings, where the string has "in" schema clause',
            schema  => [array => of => [str => {
                in=>[qw/apple apricot banana grape grapefruit/,
                     "red date", "red grape", "green grape",
                 ],
            }]],
            pos => 1,
            greedy => 1,
            description => <<'_',

Completion library can perhaps complete from the `in` value and remember
completed items when command-line option is repeated, e.g. in:

    --a1 <tab>

it will complete from any `in` value, but in:

    --a1 apple --a1 <tab>

it can exclude `apple` from the completion candidate.

Currently the completion library `Perinci::Sub::Complete` does not do this
though. Perhaps there can be an option to toggle this behavior.

_
        },
        a2 => {
            summary => 'Array with element_completion routine that generate random letter',
            schema  => ['array' => of => 'str'],
            element_completion => sub {
                my %args = @_;
                my $word = $args{word} // "";
                my $idx  = $args{index} // 0;
                [ map {$word . $_ . $idx} "a".."z" ],
            },
        },
        a3 => {
            summary => 'Array with element_completion routine that dies',
            schema  => ['array' => of => 'str'],
            element_completion => sub { die },
            description => <<'_',

See also `s3`.

_
        },
    },
};
sub test_completion {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", \%args];
}

$SPEC{sum} = {
    v => 1.1,
    summary => "Sum numbers in array",
    description => <<'_',

This function can be used to test passing nonscalar (array) arguments.

_
    args => {
        array => {
            summary => 'Array',
            schema  => ['array*', of => 'float*'],
            req     => 1,
            pos     => 0,
            greedy  => 1,
        },
        round => {
            summary => 'Whether to round result to integer',
            schema  => [bool => default => 0],
        },
    },
    examples => [
        {
            summary => 'First example',
            args    => {array=>[1, 2, 3]},
            status  => 200,
            result  => 6,
        },
        {
            summary => 'Second example, using argv',
            argv    => [qw/--round 1.1 2.1 3.1/],
            status  => 200,
            result  => 6,
        },
        {
            summary => 'Third example, invalid arguments',
            args    => {array=>[qw/a/]},
            status  => 400,
        },

        {
            summary   => 'Total numbers found in a file (4th example, bash)',
            src       => q(grep '[0-9]' file.txt | xargs sum),
            src_plang => 'bash',
        },
        {
            summary   => '2-dice roll (5th example, perl)',
            src       => <<'EOT',
my $res = sum(array=>[map {int(rand()*6+1)} 1..2]);
say $res->[2] >= 6 ? "high" : "low";
EOT
            src_plang => 'perl',
        },
    ],
    features => {},
};
sub sum {
    my %args = @_; # NO_VALIDATE_ARGS

    my $sum = 0;
    for (@{$args{array}}) {
        $sum += $_ if defined && looks_like_number($_);
    }
    $sum = int($sum) if $args{round};
    [200, "OK", $sum];
}

$SPEC{merge_hash} = {
    v => 1.1,
    summary => "Merge two hashes",
    description => <<'_',

This function can be used to test passing nonscalar (hash) arguments.

This function also tests the `x.perinci.sub.wrapper.disable_validate_args`
attribute so that `Perinci::Sub::Wrapper` does not generate argument validation
code in the wrapper. Note that by adding `# VALIDATE_ARG` in the source code,
the Dist::Zilla::Plugin::Rinci::Wrap already generates and embeds argument
validation code in the source code, so duplication is not desired, thus the
attribute.

_
    args => {
        h1 => {
            summary => 'First hash (left-hand side)',
            schema => ['hash*'],
            req => 1,
            pos => 0,
        },
        h2 => {
            summary => 'First hash (right-hand side)',
            schema => ['hash*'],
            req => 1,
            pos => 1,
        },
    },
    result => {
        schema => 'hash*',
    },
    features => {},
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub merge_hash {
    my %args = @_;
    my $h1 = $args{h1}; # VALIDATE_ARG
    my $h2 = $args{h2}; # VALIDATE_ARG

    [200, "OK", {%$h1, %$h2}];
}

$SPEC{test_validate_args} = {
    v => 1.1,
    summary => "Does nothing, only here to test # VALIDATE_ARGS",
    args => {
        a => {
            schema => "int",
        },
        b => {
            schema => [str => {min_len=>2}],
        },
        h1 => { # same as in merge_hash
            schema => 'hash',
        },
    },
    result => {
        schema => 'str*',
    },
    features => {},
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub test_validate_args {
    my %args = @_; # VALIDATE_ARGS
    [200];
}

$SPEC{undescribed_args} = {
    v => 1.1,
    summary => 'This function has several undescribed args',
    description => <<'_',

Originally added to see how peri-func-usage or `Perinci::To::Text` will display
the usage or documentation for this function.

_
    args => {
        arg1 => {},
        arg2 => {},
        arg3 => {},
        arg4 => {
            cmdline_aliases => {A=>{}},
        },
    },
};
sub undescribed_args {
    # NO_VALIDATE_ARGS
    [200];
}

$SPEC{arg_default} = {
    v => 1.1,
    summary => 'Demonstrate argument default value from default and/or schema',
    description => <<'_',

Default value can be specified in the `default` property of argument
specification, e.g.:

    args => {
        arg1 => { schema=>'str', default=>'blah' },
    },

or in the `default` clause of the argument's schema, e.g.:

    args => {
        arg1 => { schema=>['str', default=>'blah'] },
    },

or even both. The `default` property in argument specification takes precedence.

_
    args => {
        a => {
            summary => 'No defaults',
            schema  => ['int'],
        },
        b => {
            summary => 'Default from "default" property',
            default => 2,
            schema  => ['int'],
        },
        c => {
            summary => 'Default from schema',
            schema  => ['int', default => 3],
        },
        d => {
            summary => 'Default from "default" property as well as schema',
            description => <<'_',

"Default" property overrides default value from schema.

_
            default => 4,
            schema  => ['int', default=>-4],
        },
    },
};
sub arg_default {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", join("\n", map { "$_=" . ($args{$_} // "") } (qw/a b c d/))];
}

$SPEC{return_args} = {
    v => 1.1,
    summary => "Return arguments",
    description => <<'_',

Can be useful to check what arguments the function gets. Aside from normal
arguments, sometimes function will receive special arguments (those prefixed
with dash, `-`).

_
    args => {
        arg => {
            summary => 'Argument',
            schema => ['any'],
            pos => 0,
        },
    },
};
sub return_args {
    my %args = @_; # NO_VALIDATE_ARGS
    $log->tracef("return_args() is called with arguments: %s", \%args);
    [200, "OK", \%args];
}

$SPEC{test_common_opts} = {
    v => 1.1,
    summary => 'This function has arguments with the same name as Perinci::CmdLine common options',
    args => {
        help    => { schema => 'bool' },
        format  => { schema => 'str'  },
        format_options => { schema => 'str'  },
        action  => { schema => 'str'  },
        version => { schema => 'str'  },
        json    => { schema => 'bool' },
        yaml    => { schema => 'bool' },
        perl    => { schema => 'bool' },
        subcommands => { schema => 'str'  },
        cmd     => { schema => 'str'  },

        quiet   => { schema => 'bool' },
        verbose => { schema => 'bool' },
        debug   => { schema => 'bool' },
        trace   => { schema => 'bool' },
        log_level => { schema => 'str' },
    },
};
sub test_common_opts {
    my %args = @_; # NO_VALIDATE_ARGS
    [200, "OK", \%args];
}

$SPEC{gen_sample_data} = {
    v => 1.1,
    summary => "Generate sample data of various form",
    description => <<'_',

This function is first written to test `Perinci::CmdLine::Lite`'s text
formatting rules.

_
    args => {
        form => {
            schema => ['str*' => in => [qw/undef scalar aos aoaos aohos
                                           hos hohos/]],
            description => <<'_',

* aos is array of scalar, e.g. `[1,2,3]`.
* aoaos is array of aos, e.g. `[ [1,2,3], [4,5,6] ]`.
* hos is hash of scalar (values), e.g. `{a=>1, b=>2}`.
* aohos is array of array of hos, e.g. `[{a=>1,b=>2}, {a=>2}]`.
* hohos is hash of hos as values, e.g. `{row1=>{a=>1,b=>2}, row2=>{}}`.

The `aoaos` and `aohos` forms are commonly used for table data.

_
            req => 1,
            pos => 0,
        },
    },
    result => {
    },
};
sub gen_sample_data {
    my %args = @_; # NO_VALIDATE_ARGS
    my $form = $args{form};

    my $data;
    if ($form eq 'undef') {
        $data = undef;
    } elsif ($form eq 'scalar') {
        $data = 'Sample data';
    } elsif ($form eq 'aos') {
        $data = [qw/one two three four five/];
    } elsif ($form eq 'aoaos') {
        $data = [[qw/This is the first row/],
                 [qw/This is the second row/],
                 [qw/The third row this is/]];
    } elsif ($form eq 'aohos') {
        $data = [
            {field1=>11, field2=>12},
            {field1=>21, field3=>23},
            {field1=>31, field2=>32, field3=>33},
            {field2=>42},
        ];
    } elsif ($form eq 'hos') {
        $data = {
            key => 1,
            key2 => 2,
            key3 => 3,
            key4 => 4,
            key5 => 5,
        };
    } elsif ($form eq 'hohos') {
        $data = {
            {hashid=>1, key=>1},
            {hashid=>2, key2=>2},
        };
    }
    [200, "OK", $data];
}

$SPEC{test_args_as_array} = {
    v => 1.1,
    args_as => 'array',
    description => <<'_',

This function's metadata sets `args_as` property to `array`. This means it wants
to accept argument as an array, like a regular Perl subroutine accepting
positional arguments in `@_`.

_
    args => {
        a0 => { pos=>0, schema=>'str*' },
        a1 => { pos=>1, schema=>'str*' },
        a2 => { pos=>2, schema=>'str*' },
    },
};
sub test_args_as_array {
    # NO_VALIDATE_ARGS
    [200, "OK", \@_];
}

$SPEC{test_args_as_arrayref} = {
    v => 1.1,
    args_as => 'arrayref',
    description => <<'_',

This function's metadata sets `args_as` property to `arrayref`. This is just
like `array`, except the whole argument list is passed in `$_[0]`.

_
    args => {
        a0 => { pos=>0, schema=>'str*' },
        a1 => { pos=>1, schema=>'str*' },
        a2 => { pos=>2, schema=>'str*' },
    },
};
sub test_args_as_arrayref {
     # NO_VALIDATE_ARGS
    [200, "OK", $_[0]];
}

$SPEC{test_args_as_hashref} = {
    v => 1.1,
    args_as => 'hashref',
    description => <<'_',

This function's metadata sets `args_as` property to `hashref`. This is just like
`hash`, except the whole argument hash is passed in `$_[0]`.

_
    args => {
        a0 => { schema=>'str*' },
        a1 => { schema=>'str*' },
    },
};
sub test_args_as_hashref {
    my $args = shift; # NO_VALIDATE_ARGS
    [200, "OK", $args];
}

$SPEC{test_result_naked} = {
    v => 1.1,
    description => <<'_',

This function's metadata sets `result_naked` to true. This means function
returns just the value (e.g. `42`) and not with envelope (e.g. `[200,"OK",42]`).
However, when served over network Riap protocol, the function wrapper
`Perinci::Sub::Wrapper` can generate an envelope for the result, so the wrapped
function wil still return `[200,"OK",42]`.

_
    args => {
        a0 => { schema=>'str*' },
        a1 => { schema=>'str*' },
    },
    result_naked => 1,
};
sub test_result_naked {
    my %args = @_; # NO_VALIDATE_ARGS
    \%args;
}

$SPEC{test_dry_run} = {
    v => 1.1,
    summary => "Will return 'wet' if not run under dry run mode, or 'dry' if dry run",
    description => <<'_',

The way you detect whether we are running under dry-run mode is to check the
special argument `$args{-dry_run}`.

_
    args => {
    },
    features => {
        dry_run => 1,
    },
};
sub test_dry_run {
    my %args = @_; # NO_VALIDATE_ARGS
    if ($args{-dry_run}) {
        return [200, "OK", "dry"];
    } else {
        return [200, "OK", "wet"];
    }
}

$SPEC{test_binary} = {
    v => 1.1,
    summary => "Accept and send binary data",
    description => <<'_',

This function sets its argument's schema type as `buf` which indicates the
argument accepts binary data. Likewise it also sets its result's schema type as
`buf` which says that function will return binary data.

The function just returns its argument.

Note that since the metadata also contains null ("\0") in the `default` property
of the argument specification, the metadata is also not JSON-safe.

To pass binary data over JSON/Riap, you can use Riap version 1.2 and encode the
argument with ":base64" suffix, e.g.:

    $res = Perinci::Access->new->request(
        call => "http://example.com/api/Perinci/Examples/test_binary",
        {v=>1.2, args=>{"data:base64"=>"/wA="}}); # send "\xff\0"

Without `v=>1.2`, encoded argument won't be decoded by the server.

To pass binary data on the command-line, you can use `--ARG-base64` if the
command-line library provides it.

To receive binary result over JSON/Riap, you can use Riap version 1.2 which will
automatically encode binary data with base64 so it is safe when transformed as
JSON. The client library will also decode the encoded result back to the
original, so the whole process is transparent to you:

    $res = Perinci::Access->new->request(
        call => "http://example.com/api/Perinci/Examples/test_binary",
        {v=>1.2}); # => [200,"OK","\0\0\0",{}]

_
    args => {
        data => {schema=>"buf*", default=>"\0\0\0"},
    },
    result => {
        schema => "buf*",
    },
};
sub test_binary {
    my %args = @_; # NO_VALIDATE_ARGS
    my $data = $args{data} // "\0\0\0";
    return [200, "OK", $data];
}

$SPEC{gen_random_bytes} = {
    v => 1.1,
    summary => "Generate random bytes of specified length",
    description => <<'_',

This function can also be used to test binary data and Riap 1.2.

By default it will generate 1K worth of random garbage.

_
    args => {
        len => {schema=>['int*', min=>0], default=>1024},
    },
    result => {
        schema => 'buf*',
    },
};
sub gen_random_bytes {
    my %args = @_; # VALIDATE_ARGS
    my $len = $args{len} // 1024;
    [200, "OK", join("", map {chr(256*rand())} 1..$len)];
}

$SPEC{multi_status} = {
    v => 1.1,
    summary => "Example for result metadata property `results`",
    description => <<'_',

This function might return 200, 207, or 500, randomly. It will set result
metadata property `results` to contain per-item results. For more details, see
the corresponding specification in `results` property in `Rinci::resmeta`.

_
    args => {
        n => {default=>5},
    },
};
sub multi_status {
    my %args = @_; # VALIDATE_ARGS
    my $res = envresmulti();

    for (1..$args{n}) {
        my $status  = [200,500]->[2*rand];
        my $message = $status == 200 ? "OK" : "Failed";
        $res->add_result($status, $message, {item_id=>$_});
    }
    $res->as_struct;
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Perinci::Examples qw(delay);
 delay();


=head1 DESCRIPTION

This module and its submodules contain an odd mix of various functions,
variables, and other code entities, along with their L<Rinci> metadata. Mostly
used for testing Rinci specification and the various L<Perinci> modules.

Example scripts are put in a separate distribution (see
L<Perinci::Examples::Bin>) to make dependencies for this distribution minimal
(e.g. not depending on L<Perinci::CmdLine>) since this example module(s) are
usually used in the tests of other modules.


=head1 SEE ALSO

L<Perinci>

L<Perinci::Examples::Bin>

=cut
