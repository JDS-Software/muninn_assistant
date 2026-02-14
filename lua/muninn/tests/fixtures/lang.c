#include <stdio.h>

// basic function
void greet(void) {
	printf("hello\n");
}

/*
 * block comment
 */
int add(int a, int b) {
	return a + b;
}

// struct definition
struct point {
	int x;
	int y;
};

// enum definition
enum direction {
	NORTH,
	SOUTH,
	EAST,
	WEST
};

// union definition
union value {
	int i;
	float f;
};

// typedef
typedef struct {
	int x;
	int y;
} vec2;

// function pointer typedef
typedef void (*callback)(int);

// static function
static void helper(void) {
	printf("static\n");
}

// forward declaration
void forward(void);

// global variable
int global_count = 42;
