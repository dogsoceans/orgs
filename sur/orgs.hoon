/-  sg=social-graph, eng=zig-engine,
    uqbar=zig-uqbar, wallet=zig-wallet
/+  smart=zig-sys-smart
/=  con  /con/lib/orgs
|%
::  set this to the deployed orgs contract
++  orgs-contract-id  ^-  id:smart
  0x3d6b.ee91.19dd.e085.80d0.6539.4355.7aea.a598.332e.c55b.77ff.0833.4416.ad5a.83c5
::
++  orgs-contract-town  ^-  id:smart
  0x0
::
+$  org-id  id:smart  ::  ID of an *item* containing org data
::
+$  orgs-receipt
  [=org-id =hash:smart =sequencer-receipt:uqbar]
::
+$  orgs-action  (pair address:smart action:con)
--
