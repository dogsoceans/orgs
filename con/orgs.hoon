::  orgs.hoon [UQ| DAO]
::
::  manage an organization on-chain
::
::  this contract is designed to emit updates to a %social-graph.
::  orgs.hoon allows users to create user-controlled organizations.
::  control of the org is delegated to an id, which can be a
::  multisig contract, some person's address, or something else
::  entirely... to make a DAO, need to build a separate voting contract
::  that acts as an org-controller.
::
::  this version of the contract is generic. anyone can deploy
::  a new org item and use this contract logic to manage it.
::
/+  *zig-sys-smart
/=  lib  /con/lib/orgs
|_  =context
++  write
  |=  act=action:lib
  ^-  (quip call diff)
  ?:  ?=(%create -.act)
    ::  org must be created by its controller
    ?>  =(controller.org.act id.caller.context)
    =/  =item
      :*  %&
          %:  hash-data
              this.context
              controller.org.act
              town.context
              name.org.act
          ==
          this.context
          controller.org.act
          town.context
          name.org.act
          %org
          org.act
      ==
    =-  `(result ~ [item ~] ~ -)
    (produce-org-events:lib / id.p.item org.act)
  ::
  =/  org
    =+  (need (scry-state org-id.act))
    (husk org:lib - `this.context ~)
  ::  to manage, caller must control identified org
  ?>  =(id.caller.context controller.noun.org)
  =^  events  noun.org
    ?-    -.act
        %edit-org
      :-  ~
      %^  modify-org:lib
        noun.org  where.act
      |=  =org:lib
      %=    org
          desc
        ?~(desc.act desc.org desc.act)
          controller
        ?~(controller.act controller.org u.controller.act)
      ==
    ::
        %add-sub-org
      :-  (produce-org-events:lib where.act id.org org.act)
      %^  modify-org:lib
        noun.org  where.act
      |=  =org:lib
      =-  org(sub-orgs -)
      (~(put py sub-orgs.org) [name.org org]:act)
    ::
        %delete-org
      !!  ::  TODO
    ::
        %replace-members
      :-  %+  weld  (nuke-tag:lib where.act)
          (make-tag:lib where.act id.org new.act)
      %^  modify-org:lib
        noun.org  where.act
      |=(=org:lib org(members new.act))
    ::
        %add-member
      :-  (add-tag:lib where.act id.org ship.act)
      %^  modify-org:lib
        noun.org  where.act
      |=  =org:lib
      org(members (~(put pn members.org) ship.act))
    ::
        %del-member
      :-  (del-tag:lib where.act id.org ship.act)
      %^  modify-org:lib
        noun.org  where.act
      |=  =org:lib
      org(members (~(del pn members.org) ship.act))
    ==
  `(result [&+org ~] ~ ~ events)
::
++  read
  |=  =pith
  ~  ::  TODO
--
