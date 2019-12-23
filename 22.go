package main

import (
	"io/ioutil"
	"log"
	"math/big"
	"reflect"
	"regexp"
	"strconv"
	"strings"
)

type TechniqueType string

const(
	Empty TechniqueType = ""
	NewStack = "NewStack"
	Cut = "Cut"
	Increment = "increment"
)

type Technique struct {
	N int
	Type TechniqueType
}

var (
	newStackRegexp = regexp.MustCompile("deal into new stack")
	cutRegexp = regexp.MustCompile("cut (-?[0-9]+)")
	incrementRegexp = regexp.MustCompile("deal with increment ([0-9]+)")
)

func assertEqual(a, b []int) {
	if !reflect.DeepEqual(a, b) {
		log.Fatalf("Got %v, expected: %v\n", a, b)
	}
}

func makeRange(min, max int) []int {
	a := make([]int, max - min + 1)
	for i := range a {
		a[i] = min + i
	}
	return a
}

func intoNewStack(deck []int) []int {
	newDeck := make([]int, len(deck))
	for i := range deck {
		newDeck[len(deck) - i - 1] = deck[i]
	}
	return newDeck
}

func cut(deck []int, n int) []int {
	newDeck := make([]int, len(deck))
	if n > 0 {
		k := n
		for i := n; i < len(deck); i++ {
			newDeck[k - n] = deck[i]
			k++
		}
		for i := 0; i < n; i++ {
			newDeck[k - n] = deck[i]
			k++
		}
	} else {
		k := 0
		for i := len(deck) + n; i < len(deck); i++ {
			newDeck[k] = deck[i]
			k++
		}
		for i := 0; i < len(deck) + n; i++ {
			newDeck[k] = deck[i]
			k++
		}
	}
	return newDeck
}

func increment(deck []int, n int) []int {
	newDeck := make([]int, len(deck))
	for i := range deck {
		newDeck[(i * n) % len(deck)] = deck[i]
	}
	return newDeck
}

func parseTechnique(technique string) (TechniqueType, int) {
	matched := newStackRegexp.FindAllStringSubmatch(technique, -1)
	if len(matched) > 0 {
		return NewStack, -1
	}
	matched = cutRegexp.FindAllStringSubmatch(technique, -1)
	if len(matched) > 0 {
		v, _ := strconv.Atoi(matched[0][1])
		return Cut, v
	}
	matched = incrementRegexp.FindAllStringSubmatch(technique, -1)
	if len(matched) > 0 {
		v, _ := strconv.Atoi(matched[0][1])
		return Increment, v
	}
	return Empty, -1
}

func applyTechniques(deckSize int, techniques string) []int {
	deck := makeRange(0, deckSize - 1)
	for _, techniqueString := range strings.Split(techniques, "\n") {
		technique, n := parseTechnique(techniqueString)
		switch technique {
			case NewStack: deck = intoNewStack(deck)
			case Cut: deck = cut(deck, n)
			case Increment: deck = increment(deck, n)
		}
	}
	return deck
}

func tests() {
	test1, _ := ioutil.ReadFile("tests/22/1")
	assertEqual(applyTechniques(10, string(test1)), []int {0, 3, 6, 9, 2, 5, 8, 1, 4, 7})
	test2, _ := ioutil.ReadFile("tests/22/2")
	assertEqual(applyTechniques(10, string(test2)), []int {3, 0, 7, 4, 1, 8, 5, 2, 9, 6})
	test3, _ := ioutil.ReadFile("tests/22/3")
	assertEqual(applyTechniques(10, string(test3)), []int {6, 3, 0, 7, 4, 1, 8, 5, 2, 9})
	test4, _ := ioutil.ReadFile("tests/22/4")
	assertEqual(applyTechniques(10, string(test4)), []int {9, 2, 5, 8, 1, 4, 7, 0, 3, 6})
}

func solve1(techniqueString string) int {
	deck := applyTechniques(10007, techniqueString)
	for i, card := range deck {
		if card == 2019 {
			return i
		}
	}
	return -1
}

func solve2(techniquesString string) string {
	toBig := func(x int) *big.Int { return big.NewInt(int64(x)) }
	add := func(x *big.Int, y *big.Int) *big.Int { return toBig(0).Add(x, y) }
	sub := func(x *big.Int, y *big.Int) *big.Int { return toBig(0).Sub(x, y) }
	mul := func(x *big.Int, y *big.Int) *big.Int { return toBig(0).Mul(x, y) }
	mod := func(x *big.Int, mod *big.Int) *big.Int { return toBig(0).Mod(x, mod) }
	expMod := func(x *big.Int, y *big.Int, mod *big.Int) *big.Int { return toBig(0).Exp(x, y, mod) }
	deckSize, iterations := toBig(119315717514047), toBig(101741582076661)
	// every possible deck can be encoded as a pair of first number of the deck (or offset) AND difference between two adjacent numbers (or increment)
	offset, increment := toBig(0), toBig(1)
	for _, techniqueString := range strings.Split(techniquesString, "\n") {
		technique, nr := parseTechnique(techniqueString)
		n := toBig(nr)
		switch technique {
		case NewStack:
			increment = mul(increment, toBig(-1))
			offset = add(offset, increment)
		case Cut:
			offset = add(offset, mul(n, increment))
		case Increment:
			// deckSize is prime => n^(deckSize - 1) = 1 => n^(-1) === n^(deckSize - 2) mod deckSize
			deckSize2 := sub(deckSize, toBig(2))
			inverse := expMod(n, deckSize2, deckSize)
			increment = mul(increment, inverse)
		}
	}
	finalIncrement := expMod(increment, iterations, deckSize)

	// geometric series -> finalOffset = offset * (1 - increment ^ iterations) * (1 - increment)^(deckSize - 2)
	// exponentiations are done mod deckSize
	finalOffset := sub(toBig(1), expMod(increment, iterations, deckSize))
	invmod := expMod(sub(toBig(1), increment), sub(deckSize, toBig(2)), deckSize)
	finalOffset = mul(mul(finalOffset, invmod), offset)

	return mod(add(mul(toBig(2020), finalIncrement), finalOffset), deckSize).String()
}

func main() {
	tests()
	techniqueString, _ := ioutil.ReadFile("inputs/22")
	println(solve1(string(techniqueString)))
	println(solve2(string(techniqueString)))
}