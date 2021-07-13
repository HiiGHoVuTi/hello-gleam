import gleam/io
import gleam/otp/actor
import gleam/otp/process
import gleam/otp/supervisor
import library
import client
import ctimer

pub fn main() {
  let Ok(lib) = actor.start(library.initial(), library.handle)

  lib
  |> fully_init_client("Maxime", "Pattern Recognition", 4000)
  |> fully_init_client("Luce", "Harry Potter", 2000)
  |> fully_init_client("Amay", "Pattern Recognition", 3000)

  io.println("Done sending requests.")
}

pub fn fully_init_client(lib, name, likes, dt) {
  let Ok(client_) = actor.start(client.initial(lib, name, likes), client.handle)

  let timer = ctimer.new(dt)

  timer
  |> process.send(ctimer.AddNotify(
    actor: client_
    |> client.to_timer_sender,
  ))

  timer
  |> process.send(ctimer.TimeUpdate(dt: 0))

  lib
}
