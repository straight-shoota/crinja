#!/usr/bin/env bats

@test "examples/config" {
  pushd "examples/config"
  shards install

  crystal run config.cr
  crystal run config.cr --release --no-debug
  popd
}

@test "examples/kemal" {
  pushd "examples/kemal"
  shards install

  crystal build kemal.cr
  crystal build kemal.cr --release --no-debug

  popd
}

@test "examples/kilt" {
  pushd "examples/kilt"
  shards install

  crystal run kilt.cr
  crystal run kilt.cr --release --no-debug

  popd
}

@test "examples/rwbench" {
  pushd "examples/rwbench"
  shards install

  crystal run rwbench.cr
  crystal run rwbench.cr --release --no-debug

  popd
}

@test "examples/server" {
  pushd "examples/server"
  shards install

  crystal build server.cr
  crystal build server.cr --release --no-debug

  popd
}
