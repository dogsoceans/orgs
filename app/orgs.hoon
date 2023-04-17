/-  *orgs
/+  verb, dbug, default-agent, io=agentio
|%
::
::  %orgs: gall counterpart to orgs.hoon uqbar contract.
::  ingests events from the contract and inserts them into
::  our local %social-graph. maintains scry endpoints for
::  accessing information about an org, and pushes updates
::  about an org if desired by local apps.
::
::  also provides an interface for an org controller to
::  produce transactions sent to the orgs contract. (TODO)
::
+$  state  ~
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
      ::  =^  cards  state
      ::    ?+    mark  (on-poke:def mark vase)
      ::        %ping    (handle-ping:hc !<(ping vase))
      ::        %action  (handle-action:hc !<(action vase))
      ::    ==
      `this
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
:: ++  handle-ping
::   |=  =ping
::   ^-  (quip card _state)
::   !!
:: ::
:: ++  handle-action
::   |=  =action
::   ^-  (quip card _state)
::   !!
::
++  handle-scry
  |=  =path
  ^-  (unit (unit cage))
  !!
--
