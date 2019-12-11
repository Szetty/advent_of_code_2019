<?php //run with php command from `php:7.2-cli` docker image

function my_assert_handler($file, $line, $code) { echo "Assertion Failed: Line '$line'\n"; }
assert_options(ASSERT_ACTIVE, 1);
assert_options(ASSERT_WARNING, 0);
assert_options(ASSERT_BAIL, 1);
assert_options(ASSERT_CALLBACK, 'my_assert_handler');

class AmpController {
    public $codes;
    public $i;
    public $halted;

    function __construct($codes) {
        $this->codes = explode(",", $codes);
        $this->i = 0;
        $this->halted = false;
    }

    function run_program($inputs) {
        $codes = $this->codes;
        $i = $this->i;
        $input_generator = $this->build_input_generator($inputs);
        $outputs = [];
        while (true) {
            $instruction = str_pad($codes[$i], 5, "0", STR_PAD_LEFT);
            $opcode = substr($instruction, 3, 2);
            $parameter_modes = str_split(strrev(substr($instruction, 0, 3)));
            $operand = function ($offset) use ($parameter_modes, $codes, $i) {
                return (int) ($parameter_modes[$offset - 1] == "0" ? $codes[$codes[$i + $offset]] : $codes[$i + $offset]);
            };
            $store = function ($offset, $value) use(&$codes, $i) { 
                $codes[$codes[$i + $offset]] = (string) $value; 
            };
            
            switch ($opcode) {
                case "01":
                    $i += $this->add($operand, $store);
                    break;
                case "02":
                    $i += $this->multiply($operand, $store);
                    break;
                case "03":
                    if (!$input_generator->valid()) {
                        $this->codes = $codes;
                        $this->i = $i;
                        return $outputs;
                    }
                    $i += $this->input($store, $input_generator->current());
                    $input_generator->next();
                    break;
                case "04":
                    list($output, $i) = $this->output($codes, $i, $operand);
                    array_push($outputs, $output);
                    break;
                case "05":
                    $i = $this->jump_if_true($operand, $i);
                    break;
                case "06":
                    $i = $this->jump_if_false($operand, $i);
                    break;
                case "07":
                    $i += $this->less_than($operand, $store);
                    break;
                case "08":
                    $i += $this->equal($operand, $store);
                    break;
                case "99":
                    $this->halted = true;
                    return $outputs;
            }
        }
    }

    private function build_input_generator($inputs) {
        foreach($inputs as $input) {
            yield $input;
        }
    }

    private function add($operand, $store) { $store(3, $operand(1) + $operand(2)); return 4; }
    private function multiply($operand, $store) { $store(3, $operand(1) * $operand(2)); return 4; }
    private function input($store, $input) { $store(1, $input); return 2; }
    private function jump_if_true($operand, $i) { return ($operand(1) != 0 ? $operand(2) : $i + 3); }
    private function jump_if_false($operand, $i) { return ($operand(1) == 0 ? $operand(2) : $i + 3); }
    private function less_than($operand, $store) { $store(3, ($operand(1) < $operand(2) ? 1 : 0)); return 4; }
    private function equal($operand, $store) { $store(3, ($operand(1) == $operand(2) ? 1 : 0)); return 4; }
    private function output($codes, $i, $operand) { $operand1 = $operand(1); return [$operand1, $i + 2]; }
}

function permutations(array $elements) {
    if (count($elements) <= 1) {
        yield $elements;
    } else {
        foreach (permutations(array_slice($elements, 1)) as $permutation) {
            foreach (range(0, count($elements) - 1) as $i) {
                yield array_merge(
                    array_slice($permutation, 0, $i),
                    [$elements[0]],
                    array_slice($permutation, $i)
                );
            }
        }
    }
}

function solve1($codes) {
    $possible_phase_settings = ['0', '1', '2', '3', '4'];
    $max_signal = -INF;
    foreach (permutations($possible_phase_settings) as $phase_settings) {
        $signal = 0;
        foreach($phase_settings as $phase_setting) {
            $amp_controller = new AmpController($codes);
            $inputs = [$phase_setting, (string) $signal];
            $signal = (int) $amp_controller->run_program($inputs)[0];
        }
        if ($signal > $max_signal) {
            $max_signal = $signal;
        }
    }
    return $max_signal;
}

function solve2($codes) {
    $possible_phase_settings = ['9', '8', '7', '6', '5'];
    $max_signal = -INF;
    foreach (permutations($possible_phase_settings) as $phase_settings) {
        $signals = ["0"];
        $new_controller = function() use($codes) { return new AmpController($codes); };
        $amp_controllers = array_map($new_controller, range(1, 5));
        foreach($phase_settings as $i => $phase_setting) {
            $signals = $amp_controllers[$i]->run_program(array_merge([$phase_setting], $signals));
        }
        while (!$amp_controllers[4]->halted) {
            foreach($amp_controllers as $amp_controller) {
                $signals = $amp_controller->run_program($signals);
            }
        }
        $signal = (int) $signals[0];
        if ($signal > $max_signal) {
            $max_signal = $signal;
        }
    }
    return $max_signal;
}

assert(solve1("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0") == 43210);
assert(solve1("3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0") == 54321);
assert(solve1("3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0") == 65210);
assert(solve2("3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5") == 139629729);
assert(solve2("3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10") == 18216);

$codes = file_get_contents("inputs/7");
echo solve1($codes) . "\n";
echo solve2($codes) . "\n";
?>