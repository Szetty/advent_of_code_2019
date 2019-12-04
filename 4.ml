#!/usr/local/bin/ocaml

#load "str.cma";;
open Printf

let rec is_valid1 password consecutive_duplicates = 
    match password with
    | [] -> consecutive_duplicates
    | [h] -> consecutive_duplicates
    | c1 :: (c2 :: t) ->
        match compare c1 c2 with
        | 0 -> is_valid1 (c2 :: t) true
        | -1 -> is_valid1 (c2 :: t) consecutive_duplicates
        | _ -> false
;;
let is_valid1 password = is_valid1 password false;;

let rec is_valid2 password had_group_of_2 group_size = 
    match password with
    | [] -> had_group_of_2
    | [h] -> if had_group_of_2 || group_size == 2 then true else false
    | c1 :: (c2 :: t) ->
        match compare c1 c2 with
        | 0 -> is_valid2 (c2 :: t) had_group_of_2 (group_size + 1)
        | -1 -> if group_size == 2 then 
                is_valid2 (c2 :: t) true 1 
                else is_valid2 (c2 :: t) had_group_of_2 1
        | _ -> false
;;
let is_valid2 password = is_valid2 password false 1;;

let number_to_digits x = Str.split (Str.regexp "") (string_of_int x);;

let rec count_valid_passwords validator current last count =
    if current > last then
        count
    else
        let c = if validator (number_to_digits current) then 1 else 0 in
            count_valid_passwords validator (current + 1) last (count + c)
;;

let solve1 start last = count_valid_passwords is_valid1 start last 0;;
let solve2 start last = count_valid_passwords is_valid2 start last 0;;

let read =
    let ic = open_in "inputs/4" in
        let line = input_line ic in
            flush stdout;
            close_in ic;
            line;;

let line = read in 
    let chars = Str.split (Str.regexp "-") line in
        match List.map int_of_string chars with
        | [start;last] -> printf "%d\n" (solve1 start last); printf "%d\n" (solve2 start last)
        | _ -> print_string "Something went wrong"