#!/usr/local/bin/perl6

run_tests();
my $codes = "inputs/2".IO.slurp.split(',').Array;
solve1($codes);
solve2($codes, 19690720);

sub solve1($old_codes) {
    say run_program_with_noun_and_verb($codes, 12, 2)[0];
}

sub solve2($old_codes, $expected_result) {
    for 0..99 -> $noun {
        for 0..99 -> $verb {
            if run_program_with_noun_and_verb($codes, $noun, $verb)[0] == $expected_result {
                say $noun * 100 + $verb;
                return;
            }
        }
    }
}

sub run_program_with_noun_and_verb($old_codes, $noun, $verb) {
    my $codes = $old_codes.clone;
    $codes[1] = $noun;
    $codes[2] = $verb;
    run_program($codes);
}

sub run_tests() {
    run_program([1,0,0,0,99]) eqv [2,0,0,0,99] or die 'test failing for [1,0,0,0,99]';
    run_program([2,3,0,3,99]) eqv [2,3,0,6,99] or die 'test failing for [2,3,0,3,99]';
    run_program([2,4,4,5,99,0]) eqv [2,4,4,5,99,9801] or die 'test failing for [2,4,4,5,99,0]';
    run_program([1,1,1,4,99,5,6,0,99]) eqv [30,1,1,4,2,5,6,0,99] or die 'test failing for [1,1,1,4,99,5,6,0,99]';
}

sub run_program($codes) {
    loop (my $i = 0; $i < $codes.elems; $i+=4) {
        my $op_code = $codes[$i];
        if $i + 3 >= $codes.elems {
            if $op_code != 99 {
                say "Something went wrong";
            }
            last;
        }
        my $operand1 = $codes[$codes[$i + 1]];
        my $operand2 = $codes[$codes[$i + 2]];
        my $result_pos = $codes[$i + 3];
        given $op_code {
            when 1 { $codes[$result_pos] = $operand1 + $operand2 }
            when 2 { $codes[$result_pos] = $operand1 * $operand2 }
            when 99 {
                last;
            }
            default {
                say "Something went wrong";
                last;
            }
        }
    }
    return $codes;
}