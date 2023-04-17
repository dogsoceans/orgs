/-  sg=social-graph, eng=zig-engine,
    uqbar=zig-uqbar, wallet=zig-wallet
/+  smart=zig-sys-smart
/=  con  /con/lib/orgs
|%
::  set this to the deployed orgs contract
++  orgs-contract-id  ^-  id:smart
  0x1234.1234.1234.1234.1234
::
+$  org-id  id:smart  ::  ID of an *item* containing org data
::
+$  orgs-receipt
  [=org-id =hash:smart =sequencer-receipt:uqbar]
::
+$  orgs-action
  action:con
--
