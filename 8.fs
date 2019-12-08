// run with Ionide-fsharp and FSI

open System
open System.IO

let chunkStr (size: int) (str: string): string list =
    let rec chunk (s:string) accum =
        match size < s.Length with
        | true  -> chunk (s.[size..]) (s.[0..size-1]::accum)
        | false -> s::accum
    (chunk str []) |> List.rev

let buildLayers (width: int) (tallness: int) (str:string): string list list = 
    str |> chunkStr (width * tallness) |> List.map (chunkStr width)

let countCharInLayer (char: Char) (layer: string list): int =
    layer |> List.sumBy (fun x -> x |> Seq.filter (fun x -> x = char) |> Seq.length)

let solve1 (layers: string list list): int = 
    let layer = layers |> List.minBy (countCharInLayer '0')
    countCharInLayer '1' layer * countCharInLayer '2' layer

let rec transpose (listOfList: 'a list list): 'a list list = 
    match listOfList with 
    | []::_ -> []
    | _ -> List.map List.head listOfList::transpose(List.map List.tail listOfList)

let renderRow (row: string list): (string) =
    row 
    |> List.map Seq.toList 
    |> transpose 
    |> List.map (List.find (fun x -> x <> '2') >> (fun x -> if x = '1' then "*" else " "))
    |> List.reduce (+)

let solve2 (layers: string list list): string  =
    layers |> transpose |> List.map renderRow |> String.concat "\n"
   
let layers: string list list =
    "inputs/8"
    |> File.ReadAllText
    |> buildLayers 25 6

solve1 layers |> printfn "%d"
printfn "%b" (("0222112222120000" |> buildLayers 2 2 |> solve2) = "01\n10")
solve2 layers |> printfn "%s"