// basic function declaration
function greet() {
	console.log("hello");
}

// function with parameters
function add(a, b) {
	return a + b;
}

// var function expression
var multiply = function(a, b) {
	return a * b;
};

// arrow function
const handler = () => {
	console.log("handler");
};

// class declaration
class Point {
	constructor(x, y) {
		this.x = x;
		this.y = y;
	}

	toString() {
		return `(${this.x}, ${this.y})`;
	}
}

// generator function
function* counter() {
	let i = 0;
	while (true) {
		yield i++;
	}
}

// async function
async function fetchData(url) {
	const response = await fetch(url);
	return response.json();
}

// global variable
var globalCount = 42;

// IIFE callback
(function() {
	console.log("iife");
})();
