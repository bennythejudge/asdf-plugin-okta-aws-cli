#!/usr/bin/env bats

setup() {
  UTILS="${BATS_TEST_DIRNAME}/../lib/utils.bash"
}

@test "sort_versions orders releases numerically, not lexically" {
  run bash -c "source '$UTILS'; printf '%s\n' 1.10.0 1.2.0 0.9.0 2.6.0 1.2.10 0.2.1 | sort_versions"
  [ "$status" -eq 0 ]
  expected=$'0.2.1\n0.9.0\n1.2.0\n1.2.10\n1.10.0\n2.6.0'
  [ "$output" = "$expected" ]
}

@test "list_github_tags strips the refs/tags/ prefix and leading v" {
  run bash -c "
    git() {
      cat <<'EOF'
abc111	refs/tags/v0.2.1
abc222	refs/tags/v1.0.0
abc333	refs/tags/v2.6.0
EOF
    }
    source '$UTILS'
    list_github_tags
  "
  [ "$status" -eq 0 ]
  expected=$'0.2.1\n1.0.0\n2.6.0'
  [ "$output" = "$expected" ]
}

@test "release_os_arch keeps native uname casing for pre-0.3.0 releases" {
  run bash -c "
    uname() { case \"\$1\" in -s) echo Darwin ;; -m) echo x86_64 ;; esac; }
    source '$UTILS'
    release_os_arch 0.2.1
  "
  [ "$status" -eq 0 ]
  [ "$output" = "Darwin x86_64" ]
}

@test "release_os_arch lowercases darwin and maps x86_64 to amd64 from 0.3.0 onward" {
  run bash -c "
    uname() { case \"\$1\" in -s) echo Darwin ;; -m) echo x86_64 ;; esac; }
    source '$UTILS'
    release_os_arch 0.3.0
  "
  [ "$status" -eq 0 ]
  [ "$output" = "darwin amd64" ]
}

@test "release_os_arch lowercases linux and leaves arm64 unchanged from 0.3.0 onward" {
  run bash -c "
    uname() { case \"\$1\" in -s) echo Linux ;; -m) echo arm64 ;; esac; }
    source '$UTILS'
    release_os_arch 2.6.0
  "
  [ "$status" -eq 0 ]
  [ "$output" = "linux arm64" ]
}

@test "release_os_arch handles current releases on Apple Silicon" {
  run bash -c "
    uname() { case \"\$1\" in -s) echo Darwin ;; -m) echo arm64 ;; esac; }
    source '$UTILS'
    release_os_arch 2.6.0
  "
  [ "$status" -eq 0 ]
  [ "$output" = "darwin arm64" ]
}
