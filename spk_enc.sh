#!/usr/bin/atf-sh
#$
#$ Some SSL/SSH related encryption functions
#$

spk_public_key() { #$ Prepare a pulic openssh key for use
  #$ :usage: spk_public <key-file> <output>
  #$ :param key-file: public key file to use.  Will use the first `rsa` key found
  #$ :param output: output file to use
  #$
  #$ Reads a OpenSSH public key and create a key file usable by OpenSSL
  local pubkey="$1" output="$2"
  [ ! -f "$pubkey" ] && return 1 || :
  pubkey=$(awk '$1 == "ssh-rsa" { print ; exit }' < "$pubkey")
  [ -z "$pubkey" ] && return 2 || :

  local w=$(mktemp) rc=0
  (
    echo "$pubkey" > "$w"
    ssh-keygen -e -f "$w" -m PKCS8 > "$output"
  ) || rc=$?
  rm -f "$w"
  return $rc
}

spk_private_key() { #$ Prepare a private openssh key for use
  #$ :usage: spk_private [--passwd=xxx] <key-file> <output>
  #$ :param key-file: key file to use
  #$ :param output: output file to use
  #$ :param --passwd=password: password for private key
  #$
  #$ Reads a OpenSSH private key and create a key file usable by OpenSSL
  local passin=""
  while [ $# -gt 0 ]
  do
    case "$1" in
      --passwd=*) passin="${1#--passwd=}" ;;
      *) break
    esac
    shift
  done

  local privkey="$1" output="$2"
  [ ! -f "$privkey" ] && return 1 || :

  local w=$(mktemp) rc=0
  (
    cp -a "$privkey" "$w"
    if [ -n "$passin" ] ; then
      ssh-keygen -p -N '' -P "$passin" -f "$w" -m pem >/dev/null
    else
      ssh-keygen -p -N '' -f "$w" -m pem >/dev/null
    fi
    cp "$w" "$output"
  ) || rc=$?
  rm -f "$w"
  return $rc
}

spk_pem_encrypt() { #$ Encrypt `stdin` using a public `PKCS8/PEM` key
  #$ :usage: spk_pem_encrypt [--base64] <key-file>
  #$ :param --base64: if specified, data will be base64 encoded.
  #$ :param key-file: public key file to use.
  #$ :output: Encrypted data
  local encode=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      --base64) encode=true ;;
      --no-base64) encode=false ;;
      *) break
    esac
    shift
  done

  local keyfile="$1"
  [ ! -f "$keyfile" ] && return 1 || :

  local w=$(mktemp -d) rc=0
  (
    openssl rand -out "$w/secret.key" 32
    if grep -q 'BEGIN RSA PRIVATE KEY' "$keyfile" ; then
      echo "Public key required" 1>&2
      exit 1
    fi
    openssl rsautl -encrypt -oaep -pubin -inkey "$keyfile" -in "$w/secret.key" -out "$w/secret.key.enc"
    base64 < "$w/secret.key.enc"
    echo ""
    openssl aes-256-cbc -pbkdf2 -pass file:$w/secret.key $($encode && echo -a)
  ) || rc=$?
  rm -rf "$w"
  return $rc
}

spk_pem_decrypt() { #$ Decrypt `stdin` using a private `PKCS8/PEM` key.
  #$ :usage: spk_decrypt [--base64] <key-file>
  #$ :param --base64: input data is base64 encoded
  #$ :param key-file : private key file to use.
  #$ :output: De-crypted data
  local encoded=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      --base64) encoded=true ;;
      --no-base64) encoded=false ;;
      *) break
    esac
    shift
  done

  local keyfile="$1"
  [ ! -f "$keyfile" ] && return 1 || :

  local w=$(mktemp -d) rc=0
  (
    local keydat="" line
    while read -r line
    do
      [ -z "$line" ] && break || :
      keydat="$keydat$line"
    done

    echo "$keydat" | base64 -d > $w/secret.key.enc
    openssl rsautl -decrypt -oaep -inkey "$keyfile" -in "$w/secret.key.enc" -out "$w/secret.key"
    openssl aes-256-cbc -d -pbkdf2 -pass file:$w/secret.key $($encoded && echo -a)
  ) || rc=$?
  rm -rf "$w"
  return $rc
}

spk_crypt() { #$ Encrypt or decrypt `stdin` using a `ssh` public/private key.
  #$ :usage: spk_crypt [--encrypt|--decrypt] [--base64] [--passwd=xxxx] [--public|--private|--auto] <key-file>
  #$ :param --encrypt: set encrypt mode, switches to public key
  #$ :param --decrypt: set decrypt mode, switches to private key
  #$ :param --base64: if specified, data will be base64 encoded.
  #$ :param --passwd=xxxx: password for encrypted private key (if any)
  #$ :param --public: use public key, switches to encrypt
  #$ :param --private: use private key, switches to decrypt
  #$ :param --auto: key type is determined from file.
  #$ :param key-file:  key file to use.  If it contains multiple public keys, the first `rsa` key found is used.
  #$ :output: Encrypted/Decrypted data
  #|****
  local encode=false key=auto passwd="" ktype=auto mode=''
  while [ $# -gt 0 ]
  do
    case "$1" in
      --encrypt) mode=encrypt ; ktype=public ;;
      --decrypt) mode=decrypt ; ktype=private ;;
      --base64) encode=true ;;
      --no-base64) encode=false ;;
      --passwd=*) passwd=${1#--passwd=} ;;
      --public) ktype=public ; mode=encrypt ;;
      --private) ktype=private ; mode=decrypt ;;
      --auto) ktype=auto ;;
      *) break
    esac
    shift
  done

  [ -z "$mode" ] && return 2 || :
  local keyfile="$1"
  [ ! -f "$keyfile" ] && return 1 || :

  case "$ktype" in
  public|private) : ;;
  *)
    # Auto detect key type...
    if grep -q -e -BEGIN.*PRIVATE' 'KEY- "$keyfile" ; then
      ktype=private
      mode=decrypt
    else
      ktype=public
      mode=encrypt
    fi
    ;;
  esac

  local w=$(mktemp) rc=0
  (
    case "$ktype" in
      public) spk_public_key "$keyfile" "$w" ;;
      private) spk_private_key --passwd="$passwd" "$keyfile" "$w" ;;
    esac

    case "$mode" in
      encrypt) spk_pem_encrypt $($encode && echo --base64) "$w" ;;
      decrypt) spk_pem_decrypt $($encode && echo --base64) "$w" ;;
    esac
  ) || rc=$?
  rm -f "$w"
  return $rc
}

spk_encrypt() { #$ Encrypt `stdin` using a `ssh` public key.
  #$ :usage: spk_encrypt [--base64] <key-file>
  #$ :param --base64: if specified, data will be base64 encoded.
  #$ :param key-file : public key file to use.  If it contains multiple public keys, the first `rsa` key found is used.
  #$ :output: Encrypted data
  spk_crypt --encrypt "$@"
}

spk_decrypt() { #$ Decrypt `stdin` using a `ssh` private key.
  #$ :usage: spk_decrypt [--base64] [--passwd=xxxx] <key-file>
  #$ :param --base64: if specified, data will be base64 encoded.
  #$ :param --passwd=xxxx: password for encrypted private key (if any)
  #$ :param key-file:  private key file to use.  If it contains multiple public keys, the first `rsa` key found is used.
  #$ :output: Decrypted data
  spk_crypt --decrypt "$@"
}

###$_end-include
#
# Unit testing
#
[ -n "${IN_COMMON:-}" ] && return
type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/testlib/common.sh

xt_run() {
  : =descr "no."

  t=$(mktemp -d -p .)
  rc=0
  (
    pwd=RanDom1238_JKK...c
    text="Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."

    ssh-keygen -b 1024 -f "$t/openssh" -t rsa -P ''
    ssh-keygen -b 1024 -f "$t/enc" -t rsa -P "$pwd"

    ( xtf spk_private_key "$t/openssh" "$t/pem1priv" ) || exit 10
    grep -q 'BEGIN RSA PRIVATE KEY' "$t/pem1priv" || exit 11
    ( xtf spk_private_key --passwd="$pwd" "$t/enc" "$t/pem2priv" ) || exit 12
    grep -q 'BEGIN RSA PRIVATE KEY' "$t/pem2priv" || exit 13

    ( xtf spk_public_key "$t/openssh.pub" "$t/pem1pub" ) || exit 20
    grep -q 'BEGIN PUBLIC KEY' "$t/pem1pub" || exit 21
    ( xtf spk_public_key "$t/enc.pub" "$t/pem2pub" ) || exit 22
    grep -q 'BEGIN PUBLIC KEY' "$t/pem2pub" || exit 23

    [ x"$(echo "$text" | (xtf spk_pem_encrypt --base64 "$t/pem1pub" ) | (xtf spk_pem_decrypt --base64 "$t/pem1priv") )" = x"$text" ] || exit 31
    [ x"$(echo "$text" | (xtf spk_pem_encrypt "$t/pem1pub" ) | (xtf spk_pem_decrypt "$t/pem1priv") )" = x"$text" ] || exit 32

    [ x"$(echo "$text" | (xtf spk_crypt --encrypt --base64 "$t/openssh.pub" ) | (xtf spk_crypt --decrypt --base64 "$t/openssh" ))" = x"$text" ] || exit 41
    [ x"$(echo "$text" | (xtf spk_encrypt --base64 "$t/enc.pub" ) | (xtf spk_crypt --decrypt --base64 --passwd="$pwd" "$t/enc" ))" = x"$text" ] || exit 42
    [ x"$(echo "$text" | (xtf spk_crypt --encrypt "$t/openssh.pub" ) | (xtf spk_crypt --decrypt "$t/openssh" ))" = x"$text" ] || exit 41
    [ x"$(echo "$text" | (xtf spk_encrypt  "$t/enc.pub" ) | (xtf spk_crypt --decrypt --passwd="$pwd" "$t/enc" ))" = x"$text" ] || exit 42

  ) || rc=$?
  rm -rf $t
  [ $rc -eq 0 ] || atf_fail "FAIL:$rc"
  :
}

xatf_init
