#!/usr/bin/env bats

CRYSTAL=${CRYSTAL:-crystal}

@test "examples/config" {
  pushd "examples/config"
  shards install

  $CRYSTAL run config.cr
  $CRYSTAL run config.cr --release --no-debug
  popd
}

@test "examples/kemal" {
  pushd "examples/kemal"
  shards install

  $CRYSTAL build kemal.cr
  $CRYSTAL build kemal.cr --release --no-debug

  popd
}

@test "examples/kilt" {
  pushd "examples/kilt"
  shards install

  $CRYSTAL run kilt.cr
  $CRYSTAL run kilt.cr --release --no-debug

  popd
}

@test "examples/rwbench" {
  pushd "examples/rwbench"
  shards install

  $CRYSTAL run rwbench.cr
  $CRYSTAL run rwbench.cr --release --no-debug

  popd
}

@test "examples/server" {
  pushd "examples/server"
  shards install

  $CRYSTAL build server.cr
  $CRYSTAL build server.cr --release --no-debug

  popd
}
