package Perinci::Examples;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use List::Util qw(min max);
use Perinci::Sub::Util qw(gen_modified_sub);
use Scalar::Util qw(looks_like_number);

# VERSION
# DATE

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
    summary => 'This package contains various examples',
    "summary.alt.lang.id_ID" => 'Paket ini berisi berbagai contoh',
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
        },
        i0 => {
            summary => 'Integer with just "int" schema defined',
            schema  => ['int*'],
        },
        i1 => {
            summary => 'Integer with min/xmax on the schema',
            schema  => ['int*' => {min=>1, xmax=>100}],
        },
        i2 => {
            summary => 'Integer with large range min/max on the schema',
            schema  => ['int*' => {min=>1, max=>1000}],
        },
        f0 => {
            summary => 'Float with just "float" schema defined',
            schema  => ['float*'],
        },
        f1 => {
            summary => 'Float with xmin/xmax on the schema',
            schema => ['float*' => {xmin=>1, xmax=>10}],
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
        },
        a1 => {
            summary => 'Array of strings, where the string has "in" schema clause',
            schema  => [array => of => [str => {
                in=>[qw/apple apricot banana grape grapefruit/,
                     "red date", "red grape", "green grape",
                 ],
            }]],
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
        },
    },
    features => {pure => 1},
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
    "_perinci.sub.wrapper.validate_args" => 0,
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
    "_perinci.sub.wrapper.validate_args" => 0,
};
sub test_validate_args {
    my %args = @_; # VALIDATE_ARGS
    [200];
}

$SPEC{undescribed_args} = {
    v => 1.1,
    summary => 'This function has several undescribed args',
    description => <<'_',

Originally added to see how peri-func-usage or Perinci::To::Text will display
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
    [200];
}

$SPEC{arg_default} = {
    v => 1.1,
    summary => 'Demonstrate argument default value from default and/or schema',
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
    my %args = @_;
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
        subcommands => { schema => 'bool'  },
        cmd     => { schema => 'str'  },

        quiet   => { schema => 'bool' },
        verbose => { schema => 'bool' },
        debug   => { schema => 'bool' },
        trace   => { schema => 'bool' },
        log_level => { schema => 'str' },
    },
};
sub test_common_opts {
    my %args = @_;
    [200, "OK", \%args];
}

1;
# ABSTRACT: Example modules containing metadata and various example functions
__END__

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
