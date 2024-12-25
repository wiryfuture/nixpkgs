{
  lib,
  stdenv,
  fetchFromGitHub
}:
let
  rev = "54f4769a5b0e1c5bcc893d22a2731fc395f4aca0";
  version = "0-unstable-2024-12-20";
in
stdenv.mkDerivation {
  name = "openthread-border-router";
  inherit version;
  src = fetchFromGitHub {
    owner = "openthread";
    repo = "ot-br-posix";
    inherit rev;
    sha256 = "sha256-tBHfyzsuqeXlN1BJVDfjQ9fbUfLApT076N2tpJ/ZmrM=";
  };

  buildInputs = [
    wget
    iproute2
    iputils
    readline
    ncurses

    rsyslog

    dbus
    dbus_cplusplus
    avahi

    mdns

    boost

    tayga
    iptables

    bind
    openresolv

    dhcpcd
    radvd

    dnsmasq
    networkmanager

    dhcpcd

    jsoncpp

    iperf

    libnetfilter_queue

    nodejs_23

    protobuf
    protobufc
  ];

  nativeBuildInputs = [
    ninja


    pkg-config
    installShellFiles
  ];

  meta = {
    homepage = "https://openthread.io/guides/border-router";
    description = "A Thread border router for POSIX-based platforms.";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ philipwilk ];
    platforms = lib.platforms.linux; # theoretically supports darwin and bsd but that's a later problem
  };
}
