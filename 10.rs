// compiled with rustc
use std::fs;
use std::cmp::Eq;
use std::collections::HashSet;
use std::f32::consts::PI;

#[derive(Eq, PartialEq, Hash, Debug, PartialOrd, Clone, Copy, Ord)]
struct Point {
    x: i32,
    y: i32,
}

fn are_points_collinear(a: Point, b: Point, c: Point) -> bool {
    return a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y) == 0;
}

fn is_blocked(src_point: Point, dest_point: Point, points: Vec<Point>) -> bool {
    return points.iter().cloned().any(|blocking_point| {
        let are_collinear = are_points_collinear(src_point, blocking_point, dest_point);
        let is_blocking_in_between = (src_point < blocking_point && blocking_point < dest_point) || (src_point > blocking_point && blocking_point > dest_point);
        return blocking_point != src_point && blocking_point != dest_point && is_blocking_in_between && are_collinear;
    });
}

fn detectable_points(src_point: Point, points: Vec<Point>) -> Vec<Point> {
    return points.iter().cloned().filter(|dest_point| *dest_point != src_point && !is_blocked(src_point, *dest_point, points.clone())).collect();
}

fn solve1(points: Vec<Point>) -> i32 {
    return points
        .iter()
        .cloned()
        .map(|src_point| detectable_points(src_point, points.clone()).iter().count() as i32)
        .max()
        .unwrap();
}

fn angle(p0: Point, p1: Point, p2: Point) -> f32 {
    let p0p1 = (((p1.x - p0.x).pow(2) + (p1.y - p0.y).pow(2)) as f32).sqrt();
    let p0p2 = (((p2.x - p0.x).pow(2) + (p2.y - p0.y).pow(2)) as f32).sqrt();

    let dot = ((p1.x - p0.x) * (p2.x - p0.x) + (p1.y - p0.y) * (p2.y - p0.y)) as f32 / (p0p1 * p0p2);
    let cross = ((p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x)) as f32 / (p0p1 * p0p2);
    let mut angle = cross.atan2(dot);
    if angle < 0.0 {
        angle = 2.0 * PI + angle;
    }
    return angle;
}

fn solve2(points: Vec<Point>) -> i32 {
    let (_, source) = points.iter().cloned().map(|src_point| (detectable_points(src_point, points.clone()).iter().count() as i32, src_point)).max().unwrap();
    let mut remaining_points: HashSet<Point> = points.iter().cloned().collect();
    remaining_points.remove(&source);
    let mut i = 0;
    let mut last_angle = -1.0;
    let relative_point = Point{x: source.x, y: source.y - 1};
    let mut last_point = Point{x: 0, y: 0};
    while i < 200 && remaining_points.len() > 0 {
        let compute_angle_and_filter = |point| -> Option<(f32, Point)> {
            let angle = angle(source, relative_point, point);
            if angle > last_angle {
                return Some((angle, point));
            } else {
                return None;
            }
        };
        let next_target = detectable_points(source, remaining_points.iter().cloned().collect()).iter().cloned()
            .filter_map(compute_angle_and_filter)
            .min_by(|a, b| a.partial_cmp(b).unwrap());
        match next_target {
            None => {
                last_angle = -1.0;
            }
            Some((angle, point)) => {
                last_angle = angle;
                last_point = point;
                remaining_points.remove(&point);
            }
        }
        i+=1;
    }
    return last_point.x * 100 + last_point.y;
}

fn build_points(grid_str: String) -> Vec<Point> {
    let mut points: Vec<Point> = Vec::new();
    for (i, line) in grid_str.lines().enumerate() {
        for (j, cell) in line.chars().enumerate() { 
            if cell == '#' {
                points.push(Point{x: j as i32, y: i as i32});
            }
        }
    }
    return points;
}

fn run_tests() {
    let test1 = ".#..#\n.....\n#####\n....#\n...##";
    assert!(solve1(build_points(String::from(test1))) == 8);
    assert!(solve2(build_points(String::from(test1))) == 100);
    let test2 = "......#.#.\n#..#.#....\n..#######.\n.#.#.###..\n.#..#.....\n..#....#.#\n#..#....#.\n.##.#..###\n##...#..#.\n.#....####";
    assert!(solve1(build_points(String::from(test2))) == 33);
    let a = r#".#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##"#;
    assert!(solve2(build_points(String::from(a))) == 802);
}

fn main() {
    run_tests();
    let grid = fs::read_to_string("inputs/10")
        .expect("Something went wrong reading the file");

    let points = build_points(grid);
    println!("{}", solve1(points.clone()));
    println!("{}", solve2(points.clone()));
}