manhattan(_, [], 0).
manhattan([X0, Y0], [X1, Y1], Distance) :-
    Distance is abs(X0 - X1) + abs(Y0 - Y1).

compute_new_position([X0, Y0], 'R', Count, [X1, Y0]) :- X1 is X0 + Count.
compute_new_position([X0, Y0], 'L', Count, [X1, Y0]) :- X1 is X0 - Count.
compute_new_position([X0, Y0], 'U', Count, [X0, Y1]) :- Y1 is Y0 + Count.
compute_new_position([X0, Y0], 'D', Count, [X0, Y2]) :- Y2 is Y0 - Count.

move(Pos, Move, NewPos) :-
    string_chars(Move, [Direction | CountChars]),
    string_chars(CountString, CountChars),
    number_string(Count, CountString),
    compute_new_position(Pos, Direction, Count, NewPos).

calculate_points(_, [], []).
calculate_points(Pos, [Move|MoveTail], [NewPos | PointsTail]) :-
    move(Pos, Move, NewPos),
    calculate_points(NewPos, MoveTail, PointsTail).

% http://www.cs.swan.ac.uk/~cssimon/line_intersection.html
compute_intersection(0, _, _, []).
compute_intersection(Divider, [[X1, Y1], [X2, Y2]], [[X3, Y3], [X4, Y4]], Intersection) :- Divider \= 0,
    Ta is ((Y3 - Y4) * (X1 - X3) + (X4 - X3) * (Y1 - Y3)) / Divider,
    Tb is ((Y1 - Y2) * (X1 - X3) + (X2 - X1) * (Y1 - Y3)) / Divider,
    (
        (Ta >= 0, Ta =< 1, Tb >= 0, Tb =< 1) -> 
            X is X1 + Ta * (X2 - X1), Y is Y1 + Ta * (Y2 - Y1),
            Intersection = [[X, Y]];
        Intersection = []
    ).

segment_intersection([[X1, Y1], [X2, Y2]], [[X3, Y3], [X4, Y4]], Intersection) :-
    Divider is (X4 - X3) * (Y1 - Y2) - (X1 - X2) * (Y4 - Y3),
    compute_intersection(Divider, [[X1, Y1], [X2, Y2]], [[X3, Y3], [X4, Y4]], Intersection).

intersect(_, [], []).
intersect(_, [_], []).
intersect(Segment, [Point1, Point2 | T], Result) :-
    segment_intersection(Segment, [Point1, Point2], IntersectionPoint),
    intersect(Segment, [Point2 | T], IntersectionPoints),
    append(IntersectionPoint, IntersectionPoints, Result).

intersection([], _, []).
intersection([_], _, []).
intersection([Point1, Point2 | Points1], Points2, IntersectionPoints) :-
    intersect([Point1, Point2], Points2, IntersectionPoints1),
    intersection([Point2 | Points1], Points2, IntersectionPoints2),
    append(IntersectionPoints1, IntersectionPoints2, IntersectionPoints).

compute_closest_point(_, [], ClosestPoint, ClosestPoint).
compute_closest_point(Center, [Point | PointTail], CurrentClosestPoint, ClosestPoint) :-
    CurrentClosestPoint \= [],
    manhattan(Center, Point, D1),
    manhattan(Center, CurrentClosestPoint, D2),
    D1 < D2 -> 
        compute_closest_point(Center, PointTail, Point, ClosestPoint) ;
        compute_closest_point(Center, PointTail, CurrentClosestPoint, ClosestPoint).

compute_distance_to_closest_point(_, [], 0).
compute_distance_to_closest_point(Center, [IntersectionPoint | IntersectionPoints], Distance) :-
    compute_closest_point(Center, IntersectionPoints, IntersectionPoint, ClosestPoint),
    manhattan(Center, ClosestPoint, Distance).

solve1([Wire1, Wire2], Distance) :- 
    Center = [0, 0],
    calculate_points(Center, Wire1, Points1),
    calculate_points(Center, Wire2, Points2),
    intersection(Points1, Points2, IntersectionPoints),
    compute_distance_to_closest_point(Center, IntersectionPoints, Distance).

transform_points([], []).
transform_points([[XF, YF] | TF], [[XI, YI] | TI]) :-
    XI is round(XF),
    YI is round(YF),
    transform_points(TF, TI).

is_between([X0, Y0], [X1, Y1], [X, Y]) :-
    ((X >= X0, X1 >= X);(X >= X1, X0 >= X)),
    ((Y >= Y0, Y1 >= Y);(Y >= Y1, Y0 >= Y)).

size([X0, Y0], [X1, Y1], Size) :-
    (
        X0 == X1 -> Size is abs(Y1 - Y0);
        Y0 == Y1 -> Size is abs(X1 - X0)
    ).

compute_steps_to_intersection_point(IntersectionPoint, [Point1, Point2 | Points], CurrentSteps, Steps) :-
    (
        is_between(Point1, Point2, IntersectionPoint) -> 
            size(Point1, IntersectionPoint, Size),
            Steps is CurrentSteps + Size;
        size(Point1, Point2, Size),
        CurrentSteps1 is CurrentSteps + Size,
        compute_steps_to_intersection_point(IntersectionPoint, [Point2 | Points], CurrentSteps1, Steps)
    ).

compute_steps([], _, []).
compute_steps([IntersectionPoint | IntersectionPoints], Points, [StepsToIntersectionPoint | Steps]) :-
    compute_steps_to_intersection_point(IntersectionPoint, Points, 0, StepsToIntersectionPoint),
    compute_steps(IntersectionPoints, Points, Steps).

add_list_elements([], [], []).
add_list_elements([H1|T1], [H2|T2], [H|T]) :- 
    H is H1 + H2,
    add_list_elements(T1, T2, T).

solve2([Wire1, Wire2], FewestSteps) :-
    Center = [0, 0],
    calculate_points(Center, Wire1, Points1),
    calculate_points(Center, Wire2, Points2),
    intersection(Points1, Points2, IntersectionFloatPoints),
    transform_points(IntersectionFloatPoints, IntersectionPoints),
    compute_steps(IntersectionPoints, [Center | Points1], Steps1),
    compute_steps(IntersectionPoints, [Center | Points2], Steps2),
    add_list_elements(Steps1, Steps2, Steps),
    min_list(Steps, FewestSteps).

list_split_string([], []).
list_split_string([Line|Tail], [Wire | TailWires]) :-
    split_string(Line, ",", "", Wire),
    list_split_string(Tail, TailWires).

read_file(Stream,[]) :- at_end_of_stream(Stream).
read_file(Stream,[X|L]) :- \+ at_end_of_stream(Stream),
    read_line_to_string(Stream,X),
    read_file(Stream,L).

get_wires(Wires) :-
    open('inputs/3', read, Stream),
    read_file(Stream,Lines),
    close(Stream),
    list_split_string(Lines, Wires).

run_tests() :-
    Test1 = [["R8","U5","L5","D3"], ["U7","R6","D4","L4"]],
    Test2 = [
        ["R75","D30","R83","U83","L12","D49","R71","U7","L72"],
        ["U62","R66","U55","R34","D71","R55","D58","R83"]
    ],
    Test3 = [
        ["R98","U47","R26","D63","R33","U87","L62","D20","R33","U53","R51"],
        ["U98","R91","D20","R16","D67","R40","U7","R15","U6","R7"]
    ],
    solve1(Test1, 6.0),
    solve1(Test2, 159.0),
    solve1(Test3, 135.0),
    solve2(Test1, 30),
    solve2(Test2, 610),
    solve2(Test3, 410).

:- run_tests(),
   get_wires(Wires),
   solve1(Wires, Res1), write(Res1), nl,
   solve2(Wires, Res2), write(Res2), nl,
   halt.