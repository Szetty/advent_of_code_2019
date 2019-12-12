#!/usr/local/bin/clojure
(defn abs [n] (max n (- n)))
(defn gcd [a b] (if (zero? b) a (recur b, (mod a b))))
(defn lcm [a b] (/ (* a b) (gcd a b)))
(defn lcmv [v] (reduce lcm v))

(defrecord Point [x y z])
(defrecord Moon [p v])
(defn initMoons [positions] (map (fn [p] (Moon. p (Point. 0 0 0))) positions))

(defn applyGravity [moon otherMoon] (do
    (def x (+ (-> moon :v :x) (compare (-> otherMoon :p :x) (-> moon :p :x))))
    (def y (+ (-> moon :v :y) (compare (-> otherMoon :p :y) (-> moon :p :y))))
    (def z (+ (-> moon :v :z) (compare (-> otherMoon :p :z) (-> moon :p :z))))
    (assoc moon :v (Point. x y z))
))
(defn applyVelocity [moon]
    (assoc moon :p (Point. 
        (+ (-> moon :p :x) (-> moon :v :x))
        (+ (-> moon :p :y) (-> moon :v :y))
        (+ (-> moon :p :z) (-> moon :v :z))
    ))
)
(defn moveMoons [moons _step] (map (fn [moon] (applyVelocity (reduce applyGravity moon moons))) moons))
(defn energy [moon] (*
    (+ (abs (-> moon :p :x)) (abs (-> moon :p :y)) (abs (-> moon :p :z)))
    (+ (abs (-> moon :v :x)) (abs (-> moon :v :y)) (abs (-> moon :v :z)))
))
(defn totalEnergy [moons] (reduce + (map energy moons)))
(defn solve1 [moons steps] (totalEnergy (reduce #(moveMoons %1 %2) moons (range 1 (+ steps 1)))))

(defn as_start_state? [moons start dim] (and 
    (= (map #(-> %1 :p dim) moons) (get-in start [:p dim]))
    (= (map #(-> %1 :v dim) moons) (get-in start [:v dim]))
))
(defn solve2 [moons] (do
    (def start {
        :p { :x (map #(-> %1 :p :x) moons), :y (map #(-> %1 :p :y) moons), :z (map #(-> %1 :p :z) moons) },
        :v { :x (map #(-> %1 :v :x) moons), :y (map #(-> %1 :v :y) moons), :z (map #(-> %1 :v :z) moons) }
    })
    (defn find_start [dim]
        (loop [moons moons steps 1]
            (def newMoons (moveMoons moons 0))
            (if (as_start_state? newMoons start dim)
                steps
                (recur newMoons (+ steps 1))
            )
        )
    )
    (lcmv (map find_start [:x :y :z]))
))

(defn runTests [] (do
    (def test1 (initMoons [(Point. -1 0 2) (Point. 2 -10 -7) (Point. 4 -8 8) (Point. 3 5 -1)]))
    (def test2 (initMoons [(Point. -8 -10 0) (Point. 5 5 10) (Point. 2 -7 3) (Point. 9 -8 -3)]))
    (assert (= (solve1 test1 10) 179))
    (assert (= (solve1 test2 100) 1940))
    (assert (= (solve2 test1) 2772))
    (assert (= (solve2 test2) 4686774924))
))

(def mapper
    (comp
        (fn [l] (Point. (Integer. (nth l 1)) (Integer. (nth l 2)) (Integer. (nth l 3))))
        (partial re-matches #"<x=(-?[0-9]+), y=(-?[0-9]+), z=(-?[0-9]+)>")
    )
)
(def moons (initMoons (map mapper (clojure.string/split-lines (slurp "inputs/12")))))
(runTests)
(println (solve1 moons 1000))
(println (solve2 moons))