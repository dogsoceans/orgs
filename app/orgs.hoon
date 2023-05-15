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
::  they send the receipt to all ships involved in the org.
::
::  users can also manually add orgs and sync from chain!
::
::  when this app receives a receipt, it uses the output to
::  poke events into %social-graph.
::
::  app state is the set of transaction hashes we need to check
::  for inclusion/validity in the next batch. (TODO)
::
::  the actual state of the organization is maintained on-chain
::  and inside our %social-graph agent. to get info about an
::  org's member-set, just scry %social-graph.
+$  state
  $:  %0
      my-orgs=(map org-id org:con)  ::  org item ID to org
      hashes=(map hash:smart sequencer-receipt:uqbar)
      last-update-time=@da
      trackers=(map @tas @da)  ::  local apps wanting orgs-updates
  ==
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
      :-  watch-indexer:hc
      ?:  .^(? %gu /(scot %p our.bowl)/social-graph/(scot %da now.bowl)/$)
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
      |=  =old=vase
      ^-  (quip card _this)
      ?.  =(%0 -.q.old-vase)  on-init
      :_  this(state !<(_state old-vase))
      :-  watch-indexer:hc
      ?:  .^(? %gu /(scot %p our.bowl)/social-graph/(scot %da now.bowl)/$)
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
            %tracker-request
          ?>  =(src our):bowl
          =-  `state(trackers -)
          (~(put by trackers.state) !<(@tas vase) now.bowl)
            %tracker-stop
          ?>  =(src our):bowl
          `state(trackers (~(del by trackers.state) !<(@tas vase)))
            %orgs-receipt
          (ingest-receipt:hc !<(orgs-receipt vase))
            %wallet-update
          ?>  =(src our):bowl
          =+  !<(wallet-update:wallet vase)
          ?.  ?=(%sequencer-receipt -.-)  `state
          (share-receipt:hc +.-)
            %orgs-action
          ?>  =(src our):bowl
          (handle-action:hc !<(orgs-action vase))
          ::   %orgs-add
          :: ?>  =(src our):bowl
          :: `state(my-orgs (~(put by my-orgs.state) !<([id:smart @t] vase)))
          ::   %orgs-del
          :: ?>  =(src our):bowl
          :: `state(my-orgs (~(del by my-orgs.state) !<(id:smart vase)))
            %orgs-resync
          ?>  =(src our):bowl
          ::  sync our local representation to the on-chain
          ::  item for each org we know to track.
          ~&  >>  "orgs: resyncing representations to graph"
          =.  my-orgs.state
            %-  ~(urn by my-orgs.state)
            |=  [=id:smart =org:con]
            =/  =update:indexer
              .^  update:indexer  %gx
                (scot %p our.bowl)  %indexer  (scot %da now.bowl)
                /newest/item/(scot %ux orgs-contract-town)/(scot %ux id)/noun
              ==
            ?>  ?=(%newest-item -.update)
            ?>  ?=(%& -.item.update)
            ;;(org:con noun.p.item.update)
          :_  state
          (zing (turn ~(tap by my-orgs.state) org-to-graph-pokes:hc))
        ==
      [cards this]
    ::
    ++  on-agent
      |=  [=wire =sign:agent:gall]
      ^-  (quip card _this)
      ?+    wire  (on-agent:def wire sign)
          [%orgs-update @ ~]
        ::  catalog poke-acks from apps tracking us
        =/  app=@tas  i.t.wire
        ?.  ?=(%poke-ack -.sign)  `this
        ?^  p.sign
          ::  tracker failed on poke, remove them from trackers
          `this(trackers.state (~(del by trackers.state) app))
        ::  put ack-time in tracker map
        `this(trackers.state (~(put by trackers.state) app now.bowl))
      ::
          [%batch-watch ~]
        ?.  ?=(%fact -.sign)
          ?:  ?=(%kick -.sign)
            ::  attempt to re-sub
            [[watch-indexer:hc ~] this]
          (on-agent:def wire sign)
        =/  upd  !<(update:indexer q.cage.sign)
        ?.  ?=(%batch-order -.upd)  `this
        ::  when indexer has received a new batch,
        ::  check on all our txn hashes and clear
        ::  if receipts were valid. (TODO)
        `this(hashes.state ~)
      ==
    ::
    ++  on-peek   handle-scry:hc
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
  ?:  |(?=(~ path) !=(%x i.path) ?=(~ t.path))  ~
  =/  path  t.path
  ?+    path  ~
      [%get-all-orgs ~]
    ::  /get-all-orgs
    ::  returns a map of orgs
    ``orgs-update+!>(`orgs-update`[%orgs my-orgs.state])
      [%get-members ^]
    ::  /get-members/[org-id]/[sub-org]
    ::  returns (set ship)
    =/  =org-id   (slav %ux i.t.path)
    =/  =tag:con  t.t.path
    =-  ``orgs-update+!>(`orgs-update`[%members -])
    =/  res
      .^  graph-result:sg  %gx
        (scot %p our.bowl)  %social-graph  (scot %da now.bowl)
        (weld /nodes/orgs/address/(scot %ux org-id) (snoc tag %noun))
      ==
    ?>  ?=(%nodes -.res)
    %-  ~(gas in *(set ship))
    %+  murn  ~(tap in +.res)
    |=  =node:sg
    ?.(?=(%ship -.node) ~ `+.node)
  ==
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
  ~|  "orgs: couldn't find org item in modified!"
  =/  =org:con
    =-  ;;(org:con ?>(?=(%& -.-) noun.p.-))
    (got:big:eng modified.output.sequencer-receipt org-id)
  ::  make sure transaction was processed by our designated orgs contract
  ?.  =(orgs-contract-id contract.transaction.sequencer-receipt)
    ~&  >>>  "orgs: got transaction to contract other than designated one"
    `state
  ~&  >>  "orgs: ingesting receipt from {<src.bowl>}"
  ::  poke all watching trackers with update and
  ::  remove trackers who have not ack'd recently enough.
  =.  trackers.state
    %-  malt
    %+  skim  ~(tap by trackers.state)
    |=  [app=@tas last-ack=@da]
    (gte last-ack last-update-time.state)
  ::  once verified, take output and convert events to pokes
  ::  if we were not yet in this org, produce all tags for the org
  ::  and pipe them into social-graph to synchronize full state
  :_  %=  state
        my-orgs  (~(put by my-orgs.state) org-id org)
        hashes  (~(put by hashes.state) hash sequencer-receipt)
      ==
  %+  weld
    %+  make-tracker-updates
      trackers.state
    ;;(action:con calldata.transaction.sequencer-receipt)
  ?.  (~(has by my-orgs.state) org-id)
    (org-to-graph-pokes org-id org)
  %+  turn  events.output.sequencer-receipt
  |=  e=contract-event:eng
  %-  graph-poke
  ;;(org-event:con [label noun]:e)
::
::  +share-receipt: take receipt for transaction that we executed.
::  forward it to the set of ships that are members of the relevant org.
::  if the transaction was to *remove* someone, make sure to send to them too
::
++  share-receipt
  |=  [=origin:wallet =hash:smart =sequencer-receipt:uqbar]
  ^-  (quip card _state)
  ::  this receipt is sent to us from wallet, so no need to verify sigs.
  ?.  =(%0 errorcode.output.sequencer-receipt)
    ~&  >>>  "orgs: transaction failed"
    `state
  ::  grab org info from output
  ?.  =(orgs-contract-id contract.transaction.sequencer-receipt)
    ~&  >>>  "orgs: got transaction to contract other than designated one"
    `state
  ~|  "orgs: couldn't find org item in modified!"
  =/  =org-id
    (slav %ux (head q:(need origin)))
  =/  =org:con
    =-  ;;(org:con ?>(?=(%& -.-) noun.p.-))
    (got:big:eng modified.output.sequencer-receipt org-id)
  ::  get members, then poke out receipt to all
  =/  mems=(list ship)
    ~(tap pn:smart members.org)
  ::  if transaction was %del-member, send receipt to them too
  =?    mems
      ?=(%del-member p.calldata.transaction.sequencer-receipt)
    [;;(ship |2:q.calldata.transaction.sequencer-receipt) mems]
  :_  state(my-orgs (~(put by my-orgs.state) org-id org))
  %+  turn  mems
  |=  =ship
  %+  ~(poke pass:io /share-receipt)
    [ship %orgs]
  :-  %orgs-receipt
  !>(`orgs-receipt`[org-id hash sequencer-receipt])
::
::  +handle-action: process an action by a controller to edit an org.
::  will produce a transaction and send it to wallet
::
++  handle-action
  |=  =orgs-action
  ^-  (quip card _state)
  ::  if we are creating an org, calc the ID of the item
  =/  =org-id
    ?.  ?=(%create -.q.orgs-action)
      org-id.q.orgs-action
    %:  hash-data:eng
        orgs-contract-id
        p.orgs-action
        orgs-contract-town
        name.org.q.orgs-action
    ==
  =/  contract-orgs-action=action:con
    (prep orgs-action)
  :_  state  :_  ~
  %+  ~(poke pass:io /orgs-txn)
    [our.bowl %wallet]
  :-  %wallet-poke
  !>  ^-  wallet-poke:wallet
  :*  %transaction
      `[%orgs /(scot %ux org-id)]
      p.orgs-action
      orgs-contract-id
      orgs-contract-town
      noun+contract-orgs-action
  ==
::
++  prep
  |=  =orgs-action
  ^-  action:con
  |^
  ?-    -.q.orgs-action
      ?(%edit-org %delete-org %add-member %del-member)
    q.orgs-action
      %create
    q.orgs-action(org (porg org.q.orgs-action))
      %add-sub-org
    q.orgs-action(org (porg org.q.orgs-action))
  ==
  ++  porg
    |=  =org
    ^-  org:con
    :*  name.org
        parent-path.org
        desc.org
        controller.org
        (make-pset:smart ~(tap in members.org))
        sub-orgs=~
    ==
  --
::
++  graph-poke
  |=  =org-event:con
  ^-  card
  %+  ~(poke pass:io /graph-poke)
    [our.bowl %social-graph]
  social-graph-edit+!>(`edit:sg`[%orgs org-event])
::
++  make-member-tags
  |=  [=id:smart =org:con]
  ^-  (list card)
  %+  turn  ~(tap pn:smart members.org)
  |=  =ship
  %-  graph-poke
  :^  %add-tag
    (snoc parent-path.org name.org)
  [%address id]  [%ship ship]
::
::  for an org, at every level of sub-org, clear the
::  existing data, if any, and produce pokes to synchronize
::  member-set with what's on-chain.
::
++  org-to-graph-pokes
  |=  [=id:smart =org:con]
  ^-  (list card)
  ~&  >  org
  :-  (graph-poke [%nuke-tag (snoc parent-path.org name.org)])
  %-  zing
  :-  (make-member-tags id org)
  ^-  (list (list card))
  %+  turn  ~(val py:smart sub-orgs.org)
  |=  sub=org:con
  ^$(org sub)
::
++  watch-indexer
  ^-  card
  %+  ~(watch pass:io /batch-watch)  [our.bowl %uqbar]
  /indexer/orgs/batch-order/(scot %ux orgs-contract-town)
::
++  make-tracker-updates
  |=  [trackers=(map @tas @da) =action:con]
  ^-  (list card)
  %+  turn  ~(tap in ~(key by trackers))
  |=  app=@tas
  %+  ~(poke pass:io /orgs-update/[app])
  [our.bowl app]  orgs-action+!>(action)
--
