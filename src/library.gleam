import gleam/io
import gleam/list
import gleam/string
import gleam/map.{Map}
import gleam/result
import gleam/otp/process
import gleam/otp/actor

pub type Book {
  Book(name: String, id: Int, contents: String)
}

pub type State {
  State(name: String, books: Map(String, Book))
}

pub type Message {
  Order(name: String, buyer: #(String, process.Sender(Result(Book, Nil))))
  Return(book: Book)
}

pub type MessageBack =
  Result(Book, Nil)

pub fn initial() -> State {
  State(
    name: "My library",
    books: map.from_list(
      [
        Book(
          name: "Harry Potter",
          id: 1451112,
          contents: "Harry was a wizard...",
        ),
        Book(
          name: "Pattern Recognition",
          id: 7854155,
          contents: "The fundamentals of AI lie in...",
        ),
        Book(
          name: "Dictionary",
          id: 472312,
          contents: "A: first letter of the...",
        ),
      ]
      |> list.map(fn(b: Book) { #(b.name, b) }),
    ),
  )
}

pub fn handle(msg: Message, state: State) {
  case msg {
    Order(..) -> handle_order
    Return(..) -> handle_return
  }(
    msg,
    state,
  )
}

fn print_state(new_books: Map(String, Book)) {
  io.println(
    "New State after that:"
    |> string.append(string.concat(
      new_books
      |> map.keys
      |> list.map(fn(name) { string.concat(["\n  - ", name]) }),
    )),
  )
}

fn handle_order(msg: Message, state: State) {
  let State(books: books, ..) = state
  assert Order(name: wanted, buyer: #(buyer, callback)) = msg

  io.println(string.concat([buyer, " is trying to buy ", wanted]))

  let found =
    books
    |> map.get(wanted)

  process.send(callback, found)

  let new_books =
    books
    |> map.delete(wanted)

  print_state(new_books)

  actor.Continue(State(..state, books: new_books))
}

fn handle_return(msg: Message, state: State) {
  let State(books: books, ..) = state
  assert Return(book) = msg

  io.println(string.concat(["Someone is returning ", book.name]))

  let new_books =
    books
    |> map.insert(book.name, book)

  print_state(new_books)

  actor.Continue(State(..state, books: new_books))
}
