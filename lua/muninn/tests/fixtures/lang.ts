// basic function
function greet(): void {
	console.log("hello");
}

// typed parameters
function add(a: number, b: number): number {
	return a + b;
}

// interface definition
interface Point {
	x: number;
	y: number;
}

// type alias
type Direction = "north" | "south" | "east" | "west";

// class with types
class Vector {
	constructor(public x: number, public y: number) {}

	magnitude(): number {
		return Math.sqrt(this.x ** 2 + this.y ** 2);
	}
}

// const arrow function
const multiply = (a: number, b: number): number => {
	return a * b;
};

// enum declaration
enum Color {
	Red,
	Green,
	Blue,
}

// generic function
function identity<T>(arg: T): T {
	return arg;
}

// async function
async function fetchData(url: string): Promise<Response> {
	return fetch(url);
}

// global variable
var globalCount: number = 42;
