import library.{Book}
import gleam/io
import gleam/int
import gleam/map.{Map}
import gleam/otp/actor
import gleam/otp/process
import gleam/result
import ctimer

pub type Message {
  Prompt
  Demand
  DoneReading
}

pub type State {
  State(
    lib: process.Sender(library.Message),
    name: String,
    likes: String,
    books: Map(String, Book),
  )
}

pub fn initial(
  lib: process.Sender(library.Message),
  name: String,
  likes: String,
) {
  State(lib, name, likes, books: map.from_list([]))
}

pub fn handle(msg: Message, state: State) {
  case msg {
    Prompt ->
      state.books
      |> map.get(state.likes)
      |> result.is_error
      |> fn(cond) {
        case cond {
          True -> order
          False -> return
        }
      }
    Demand -> order
    DoneReading -> return
  }(
    msg,
    state,
  )
}

pub fn to_timer_sender(
  client: process.Sender(Message),
) -> process.Sender(ctimer.Message) {
  process.map_sender(client, fn(_) { Prompt })
}

pub fn order(_msg: Message, state: State) {
  let #(sender, receiver) = process.new_channel()

  state.lib
  |> process.send(library.Order(name: state.likes, buyer: #(state.name, sender)))

  let new_books =
    receiver
    |> process.receive(100)
    |> result.flatten
    |> result.map(fn(acquired_book: library.Book) {
      state.books
      |> map.insert(acquired_book.name, acquired_book)
    })
    |> result.unwrap(or: state.books)

  actor.Continue(State(..state, books: new_books))
}

pub fn return(_msg: Message, state: State) {
  let #(Ok(returned), new_books) =
    state.books
    |> map.get(state.likes)
    |> result.map(fn(book: library.Book) {
      #(
        Ok(book),
        state.books
        |> map.delete(state.likes),
      )
    })
    |> result.unwrap(or: #(Error(Nil), state.books))

  state.lib
  |> process.send(library.Return(returned))

  actor.Continue(State(..state, books: new_books))
}
