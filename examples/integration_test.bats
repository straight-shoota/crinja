#!/usr/bin/env bats

CRYSTAL=${CRYSTAL:-crystal}

@test "config" {
  pushd "config"
    shards install
    $CRYSTAL run config.cr
  popd
}

@test "kemal" {
  pushd "kemal"
    shards install
    $CRYSTAL build kemal.cr
  popd
}

@test "kilt" {
  pushd "kilt"
    shards install
    $CRYSTAL run kilt.cr
  popd
}

@test "rwbench" {
  pushd "rwbench"
    shards install
    $CRYSTAL run rwbench.cr
  popd
}

@test "server" {
  pushd "server"
    shards install
    $CRYSTAL build server.cr
  popd
}
