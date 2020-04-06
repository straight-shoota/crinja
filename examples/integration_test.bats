#!/usr/bin/env bats

CRYSTAL=${CRYSTAL:-crystal}

@test "examples/config" {
  pushd "examples/config"
  shards install

  $CRYSTAL run config.cr
  popd
}

@test "examples/kemal" {
  pushd "examples/kemal"
  shards install

  $CRYSTAL build kemal.cr

  popd
}

@test "examples/kilt" {
  pushd "examples/kilt"
  shards install

  $CRYSTAL run kilt.cr

  popd
}

@test "examples/rwbench" {
  pushd "examples/rwbench"
  shards install

  $CRYSTAL run rwbench.cr

  popd
}

@test "examples/server" {
  pushd "examples/server"
  shards install

  $CRYSTAL build server.cr

  popd
}
