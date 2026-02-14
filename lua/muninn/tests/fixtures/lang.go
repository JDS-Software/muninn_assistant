package main

import "fmt"

// basic function
func greet() {
	fmt.Println("hello")
}

/*
 * block comment function
 */
func add(a, b int) int {
	return a + b
}

// method declaration
func (p Point) String() string {
	return fmt.Sprintf("(%d, %d)", p.X, p.Y)
}

// struct type
type Point struct {
	X int
	Y int
}

// interface type
type Greeter interface {
	Greet() string
}

// anonymous function assignment
var handler = func() {
	fmt.Println("handler")
}

// multi-return function
func divide(a, b float64) (float64, error) {
	if b == 0 {
		return 0, fmt.Errorf("zero")
	}
	return a / b, nil
}

// variadic function
func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

// global variable
var globalCount = 42
