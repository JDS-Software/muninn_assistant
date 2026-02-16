# basic function
def greet():
    print("hello")


# function with parameters
def add(a, b):
    return a + b


# class definition
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    # string representation
    def __str__(self):
        return f"({self.x}, {self.y})"


# decorated function
@cache
def expensive():
    return compute()


# decorated class
@dataclass
class Config:
    name: str
    value: int


# async function
async def fetch(url):
    return await get(url)


# multiple decorators
@app.route("/")
@login_required
def index():
    return "home"
