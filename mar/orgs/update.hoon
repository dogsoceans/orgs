/-  orgs
=,  enjs:format
|_  upd=orgs-update:orgs
++  grab
  |%
  ++  noun  orgs-update:orgs
  --
::
++  grow
  |%
  ++  noun  upd
  ++  json
    |^
    ?-    -.upd
        %members
      a+(turn ~(tap in +.upd) |=(s=@p (ship s)))
    ::
        %orgs
      %-  pairs
      %+  turn  ~(tap by +.upd)
      |=  [org-id=@ux =org:con:orgs]
      [(scot %ux org-id) (enjs-org org)]
    ==
    ::
    ++  enjs-org
      |=  =org:con:orgs
      ^-  ^json
      %-  pairs
      :~  ['name' s+name.org]
          ['parent-path' (path parent-path.org)]
          ['desc' ?~(desc.org s+'' s+u.desc.org)]
          ['controller' s+(scot %ux controller.org)]
          :-  'members'
          :-  %a
          %+  turn
            ~(tap pn:smart:orgs members.org)
          |=(s=@p (ship s))
          :-  'sub-orgs'
          %-  pairs
          %+  turn  ~(tap py:smart:orgs sub-orgs.org)
          |=  [name=@t =org:con:orgs]
          [name (enjs-org org)]
      ==
    --
  --
::
++  grad  %noun
::
--
