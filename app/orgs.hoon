/-  *orgs
/+  verb, dbug, default-agent, io=agentio, sig=zig-sig
|%
::
::  %orgs: gall counterpart to orgs.hoon uqbar contract.
::  ingests events from the contract and inserts them into
::  our local %social-graph. also provides an interface
::  for an org controller to produce transactions sent to
::  the orgs contract.
::
::  chain info is sourced from receipts. every time an org's
::  controller performs a transaction that modifies the org,
::  they should send the receipt to all ships involved in the
::  org. (TODO also use indexer as backup source)
::
::  when this app receives a receipt, it uses the output to
::  poke events into %social-graph, and makes a note to check
::  the transaction-hash on the next batch to confirm that the
::  receipt was non-fraudulent.
::
::  app state is the set of transaction hashes we need to check
::  for inclusion/validity in the next batch. (TODO)
::
::  the actual state of the organization is maintained on-chain
::  and inside our %social-graph agent. to get info about an
::  org's member-set, just scry %social-graph.
+$  state  [%0 hashes=(map hash:smart sequencer-receipt:uqbar)]
+$  card  card:agent:gall
--
::
^-  agent:gall
%+  verb  &
%-  agent:dbug
=|  =state
=<  |_  =bowl:gall
    +*  this  .
        hc    ~(. +> bowl)
        def   ~(. (default-agent this %|) bowl)
    ::
    ++  on-init
      :_  this(state *_state)
      ?:  .^(? %gu /(scot %p our.bowl)/social-graph/(scot %da now.bowl))
        ~
      ~&  >>>  "orgs: error: must have %social-graph installed"
      ~&  >>>  "automatically installing %nectar from ~bacrys now"
      :_  ~
      :*  %pass  /nectar-install  %agent  [our.bowl %hood]  %poke
          %kiln-install  !>([%nectar ~bacrys %nectar])
      ==
    ::
    ++  on-save  !>(state)
    ::
    ++  on-load
      |=  old=vase
      ^-  (quip card _this)
      :_  this(state !<(_state old))
      ?:  .^(? %gu /(scot %p our.bowl)/social-graph/(scot %da now.bowl))
        ~
      ~&  >>>  "orgs: error: must have %social-graph installed"
      ~&  >>>  "automatically installing %nectar from ~bacrys now"
      :_  ~
      :*  %pass  /nectar-install  %agent  [our.bowl %hood]  %poke
          %kiln-install  !>([%nectar ~bacrys %nectar])
      ==
    ::
    ++  on-poke
      |=  [=mark =vase]
      ^-  (quip card _this)
      =^  cards  state
        ?+    mark  (on-poke:def mark vase)
            %orgs-receipt
          (ingest-receipt:hc !<(orgs-receipt vase))
            %orgs-action
          ?>  =(src our):bowl
          (handle-action:hc !<(orgs-action vase))
            %wallet-update
          ?>  =(src our):bowl
          =+  !<(wallet-update:wallet vase)
          ?.  ?=(%sequencer-receipt -.-)  `state
          (share-receipt:hc |2:-)
        ==
      [cards this]
    ::
    ++  on-peek   handle-scry:hc
    ++  on-agent  on-agent:def
    ++  on-watch  on-watch:def
    ++  on-arvo   on-arvo:def
    ++  on-leave  on-leave:def
    ++  on-fail   on-fail:def
    --
::
|_  bowl=bowl:gall
++  handle-scry
  |=  =path
  ^-  (unit (unit cage))
  !!
::
::  +ingest-receipt: take receipt from org controller, and generate
::  pokes to %social-graph. store hash in state until next batch
::
++  ingest-receipt
  |=  orgs-receipt
  ^-  (quip card _state)
  ::  verify signatures of sequencer
  =/  known-sequencer
    .^  (unit (pair address:smart ship))  %gx
      (scot %p our.bowl)  %uqbar  (scot %da now.bowl)
      /sequencer-on-town/(scot %ux town.transaction.sequencer-receipt)/noun
    ==
  ?~  known-sequencer
    ~&  >>>  "orgs: failed to get sequencer info from %uqbar"
    `state
  ?.  =(q.u.known-sequencer q.ship-sig.sequencer-receipt)
    ~&  >>>  "orgs: received receipt from unknown sequencer"
    `state
  ~|  "orgs: received invalid signature on sequencer receipt!"
  =+  (sham |3:sequencer-receipt)
  ?>  (validate:sig our.bowl ship-sig.sequencer-receipt - now.bowl)
  ?>  (uqbar-validate:sig p.u.known-sequencer - uqbar-sig.sequencer-receipt)
  ::  make sure transaction was processed by our designated orgs contract
  ?.  =(orgs-contract-id contract.transaction.sequencer-receipt)
    ~&  >>>  "orgs: got transaction to contract other than designated one"
    `state
  ::  once verified, take output and convert events to pokes
  :_  state(hashes (~(put by hashes.state) hash sequencer-receipt))
  %+  turn  events.output.sequencer-receipt
  |=  e=contract-event:eng
  %+  ~(poke pass:io /graph-poke)
    [our.bowl %social-graph]
  :-  %social-graph-edit
  !>  ^-  edit:sg
  [%orgs ;;(org-event:con [label noun]:e)]
::
::  +take-our-receipt: take receipt for transaction that we executed.
::  forward it to the set of ships that are members of the relevant org
::
++  share-receipt
  |=  [=hash:smart =sequencer-receipt:uqbar]
  ^-  (quip card _state)
  ::  this receipt is sent to us from wallet, so no need to verify sigs.
  ::  grab org info from output
  ?.  =(orgs-contract-id contract.transaction.sequencer-receipt)
    ~&  >>>  "orgs: got transaction to contract other than designated one"
    `state
  ~|  "orgs: couldn't find org item in modified!"
  =/  =org-id
    -.-.modified.output.sequencer-receipt
  =/  =org:con
    =-  ;;(org:con ?>(?=(%& -.-) noun.p.-))
    (got:big:eng modified.output.sequencer-receipt org-id)
  ::  scry %social-graph for members, then poke out receipt to all
  =/  mems=(list ship)
    =-  ?.  ?=(%nodes -.-)  ~
        (murn ~(tap in +.-) |=(n=node:sg ?:(?=(%ship -.n) `+.n ~)))
    .^  graph-result:sg  %gx
      (scot %p our.bowl)  %social-graph  (scot %da now.bowl)
      /nodes/orgs/entity/(scot %t name.org)/(scot %t name.org)/noun
    ==
  :_  state
  %+  turn  mems
  |=  =ship
  %+  ~(poke pass:io /share-receipt)
    [ship %orgs]
  orgs-receipt+!>(`orgs-receipt`[org-id hash sequencer-receipt])
::
::  +handle-action: process an action by a controller to edit an org.
::  will produce a transaction and send it to wallet
::
++  handle-action
  |=  act=orgs-action
  ^-  (quip card _state)
  !!
--
