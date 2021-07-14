import gleam/io
import gleam/list
import gleam/string
import gleam/function
import gleam/map.{Map}
import gleam/result
import gleam/otp/process
import gleam/otp/actor

pub type Book {
  Book(name: String, category: String, id: Int, contents: String)
}

pub type State {
  State(name: String, books: Map(String, List(Book)))
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
    books: [
      Book(
        name: "Harry Potter",
        category: "Fantasy",
        id: 1451112,
        contents: "Harry was a wizard...",
      ),
      Book(
        name: "Pattern Recognition",
        category: "Science",
        id: 7854155,
        contents: "The fundamentals of AI lie in...",
      ),
      Book(
        name: "Neuroscience for Beginners",
        category: "Science",
        id: 45424153,
        contents: "The brain is a fascinating organ...",
      ),
      Book(
        name: "Dictionary",
        category: "English",
        id: 472312,
        contents: "A: first letter of the...",
      ),
    ]
    |> list.fold(
      map.new(),
      fn(book: Book, curr: Map(String, List(Book))) {
        curr
        |> map.update(
          book.category,
          fn(entry: Result(List(Book), Nil)) {
            case entry {
              Ok(books) -> [book, ..books]
              Error(_) -> [book]
            }
          },
        )
      },
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

fn handle_order(msg: Message, state: State) {
  let State(books: books, ..) = state
  assert Order(name: wanted, buyer: #(buyer, callback)) = msg

  io.println(string.concat([buyer, " is trying to buy a ", wanted, " book"]))

  let found =
    books
    |> map.get(wanted)
    |> result.map(list.head)
    |> result.flatten

  let _ =
    found
    |> result.map(fn(b: Book) {
      io.println(string.concat([buyer, " bought ", b.name]))
    })

  process.send(callback, found)

  let new_books =
    books
    |> map.update(
      wanted,
      fn(e) {
        e
        |> result.unwrap(or: [])
        |> list.tail
        |> result.unwrap(or: [])
      },
    )

  actor.Continue(State(..state, books: new_books))
}

fn handle_return(msg: Message, state: State) {
  let State(books: books, ..) = state
  assert Return(book) = msg

  io.println(string.concat(["Someone is returning ", book.name]))

  let new_books =
    books
    |> map.update(
      book.category,
      fn(cat: Result(List(Book), Nil)) {
        case cat {
          Ok(lst) -> [book, ..lst]
          Error(_) -> [book]
        }
      },
    )

  actor.Continue(State(..state, books: new_books))
}
