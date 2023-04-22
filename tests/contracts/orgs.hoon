::
::  tests for con/orgs.hoon
::
/+  *test, *transaction-sim
/=  org-lib  /con/lib/orgs
/*  orgs-contract  %jam  /con/compiled/orgs/jam
|%
::
::  test data
::
++  sequencer  caller-1
++  caller-1  ^-  caller:smart  [addr-1 1 (id addr-1)]:zigs
++  caller-2  ^-  caller:smart  [addr-2 1 (id addr-2)]:zigs
++  caller-3  ^-  caller:smart  [addr-3 1 (id addr-3)]:zigs
++  caller-4  ^-  caller:smart  [addr-4 1 (id addr-4)]:zigs
::
++  my-shell  ^-  shell:smart
  [caller-1 ~ id.p:orgs-pact [1 1.000.000] default-town-id 0]
::
++  orgs-pact
  ^-  item:smart
  =/  code  (cue orgs-contract)
  =/  id  (hash-pact:smart 0x1234.5678 0x1234.5678 default-town-id code)
  :*  %|  id
      0x1234.5678  ::  source
      0x1234.5678  ::  holder
      default-town-id
      [-.code +.code]
      ~
  ==
::
++  my-test-org-id
  ^-  id:smart
  %:  hash-data:smart
      id.p:orgs-pact
      addr-1:zigs
      default-town-id
      'my-test-org'
  ==
++  my-test-org
  |=  =org:org-lib
  ^-  item:smart
  :*  %&  my-test-org-id
      id.p:orgs-pact
      addr-1:zigs
      default-town-id
      'my-test-org'
      %org
      org
  ==
::
++  state
  %-  make-chain-state
  :~  orgs-pact
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
          ==
      ==
      (account addr-1 300.000.000 ~):zigs
      (account addr-2 200.000.000 ~):zigs
  ==
++  chain
  ^-  chain:engine
  [state ~]
::
::  tests for %create
::
++  test-zz-create  ^-  test-txn
  =/  my-org
    ^-  org:org-lib
    :*  'squidz'
        /
        `'an organization for squids'
        addr-1:zigs
        (make-pset:smart ~[~hodzod ~walrus])
        ~
    ==
  =/  org-item
    ^-  item:smart
    :+  %&
      (hash-data:smart id.p:orgs-pact addr-1:zigs default-town-id 'squidz')
    [id.p:orgs-pact addr-1:zigs default-town-id 'squidz' %org my-org]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%create my-org] my-shell]
  :*  gas=~
      errorcode=`%0
      modified=`(make-chain-state ~[org-item])
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/squidz [%address id.p.org-item] [%ship ~hodzod]]
          :+  id.p:orgs-pact  %add-tag
          [/squidz [%address id.p.org-item] [%ship ~walrus]]
      ==
  ==
::
++  test-zy-create-not-controller  ^-  test-txn
  =/  my-org
    ^-  org:org-lib
    :*  'squidz'
        /
        `'an organization for squids'
        addr-1:zigs
        (make-pset:smart ~[~hodzod ~walrus])
        ~
    ==
  =/  org-item
    ^-  item:smart
    :+  %&
      (hash-data:smart id.p:orgs-pact addr-1:zigs default-town-id 'squidz')
    [id.p:orgs-pact addr-1:zigs default-town-id 'squidz' %org my-org]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    =-  [fake-sig [%create my-org] -]
    [caller-2 ~ id.p:orgs-pact [1 1.000.000] default-town-id 0]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-zx-create-with-sub-orgs  ^-  test-txn
  =/  my-org
    ^-  org:org-lib
    :*  'squidz'
        /
        `'an organization for squids'
        addr-1:zigs
        (make-pset:smart ~[~hodzod ~walrus])
        %-  make-pmap:smart
        :~  :-  'loach'
            ['loach' /squidz ~ addr-1:zigs (make-pset:smart ~[~hodzod]) ~]
            :-  'loch'
            ['loch' /squidz ~ addr-1:zigs (make-pset:smart ~[~walrus]) ~]
        ==
    ==
  =/  org-item
    ^-  item:smart
    :+  %&
      (hash-data:smart id.p:orgs-pact addr-1:zigs default-town-id 'squidz')
    [id.p:orgs-pact addr-1:zigs default-town-id 'squidz' %org my-org]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%create my-org] my-shell]
  :*  gas=~
      errorcode=`%0
      modified=`(make-chain-state ~[org-item])
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/squidz [%address id.p.org-item] [%ship ~hodzod]]
          :+  id.p:orgs-pact  %add-tag
          [/squidz [%address id.p.org-item] [%ship ~walrus]]
          :+  id.p:orgs-pact  %add-tag
          [/squidz/loach [%address id.p.org-item] [%ship ~hodzod]]
          :+  id.p:orgs-pact  %add-tag
          [/squidz/loch [%address id.p.org-item] [%ship ~walrus]]
      ==
  ==
::
::  tests for %edit-org
::
++  test-yz-edit-org-not-controller  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    =+  [caller-2 ~ id.p:orgs-pact [1 1.000.000] default-town-id 0]
    [fake-sig [%edit-org my-test-org-id /my-test-org `'newdesc' ~] -]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-yy-edit-org
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%edit-org my-test-org-id /my-test-org `'newdesc' ~] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'newdesc'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
          ==
      ==
      burned=`~
      events=`~
  ==
::
++  test-yx-edit-sub-org
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    :+  fake-sig
      [%edit-org my-test-org-id /my-test-org/my-sub-org `'newdesc' ~]
    my-shell
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org `'newdesc' addr-2:zigs ~ ~]
          ==
      ==
      burned=`~
      events=`~
  ==
::
++  test-yw-edit-sub-org-controller  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    :+  fake-sig
      [%edit-org my-test-org-id /my-test-org/my-sub-org ~ `addr-1:zigs]
    my-shell
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-1:zigs ~ ~]
          ==
      ==
      burned=`~
      events=`~
  ==
::
++  test-yv-edit-sub-org-nonexistent  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    :+  fake-sig
      [%edit-org my-test-org-id /my-test-org/not-here `'newdesc' ~]
    my-shell
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
::  tests for %add-sub-org
::
++  test-xz-add-sub-org  ^-  test-txn
  =/  loach-sub-org
    ^-  org:org-lib
    ['loach' /my-test-org ~ addr-1:zigs (make-pset:smart ~[~hodzod]) ~]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-sub-org my-test-org-id / loach-sub-org] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          ^-  (list [@t org:org-lib])
          :~  ['my-sub-org' ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]]
              ['loach' loach-sub-org]
          ==
      ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org/loach [%address my-test-org-id] [%ship ~hodzod]]
      ==
  ==
::
++  test-xy-add-sub-org-name-already-taken  ^-  test-txn
  =/  my-sub-org
    ^-  org:org-lib
    ['my-sub-org' /my-test-org ~ addr-1:zigs (make-pset:smart ~[~hodzod]) ~]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-sub-org my-test-org-id / my-sub-org] my-shell]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-xx-add-sub-org-bad-path  ^-  test-txn
  =/  loach-sub-org
    ^-  org:org-lib
    ['loach-sub-org' /my-test-org ~ addr-1:zigs (make-pset:smart ~[~hodzod]) ~]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-sub-org my-test-org-id /not/here loach-sub-org] my-shell]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-xw-add-sub-org-missing-path  ^-  test-txn
  =/  loach-sub-org
    ^-  org:org-lib
    ['loach-sub-org' /my-test-org ~ addr-1:zigs (make-pset:smart ~[~hodzod]) ~]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-sub-org my-test-org-id /not-here loach-sub-org] my-shell]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-xv-add-sub-org-to-sub-org  ^-  test-txn
  =/  loach-sub-org
    ^-  org:org-lib
    ['loach' /my-test-org/my-sub-org ~ addr-1:zigs (make-pset:smart ~[~hodzod]) ~]
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-sub-org my-test-org-id /my-test-org/my-sub-org loach-sub-org] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :_  ~
          :-  'my-sub-org'
          :*  'my-sub-org'  /my-test-org  ~  addr-2:zigs  ~
              %-  make-pmap:smart
              :_  ~
              ['loach' loach-sub-org]
          ==
      ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org/my-sub-org/loach [%address my-test-org-id] [%ship ~hodzod]]
      ==
  ==
::
::  tests for %delete-org
::
++  test-wz-delete-org  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%delete-org my-test-org-id /my-test-org ~] my-shell]
  :*  gas=~
      errorcode=`%0
      modified=`~
      ::  burned
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
          ==
      ==
      ::  events
      `[id.p:orgs-pact %nuke-top-level-tag /my-test-org]^~
  ==
::
++  test-wy-delete-org-empty-path  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%delete-org my-test-org-id / ~] my-shell]
  :*  gas=~
      errorcode=`%0
      modified=`~
      ::  burned
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
          ==
      ==
      ::  events
      `[id.p:orgs-pact %nuke-top-level-tag /my-test-org]^~
  ==
::
++  test-wx-delete-sub-org  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%delete-org my-test-org-id /my-test-org/my-sub-org ~] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          ~
      ==
      burned=`~
      ::  events
      `[id.p:orgs-pact %nuke-tag /my-test-org/my-sub-org]^~
  ==
::
++  test-ww-delete-nonexistent-sub-org  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%delete-org my-test-org-id /my-test-org/not-here ~] my-shell]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
::  tests for %replace-members (TODO)
::
::
::  tests for %add-member
::
++  test-vz-add-member  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-member my-test-org-id /my-test-org ~sampel] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus ~sampel])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org [%address my-test-org-id] [%ship ~sampel]]
      ==
  ==
::
++  test-vy-add-member-empty-path  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-member my-test-org-id / ~sampel] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus ~sampel])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org [%address my-test-org-id] [%ship ~sampel]]
      ==
  ==
::
++  test-vx-add-member-sub-org  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-member my-test-org-id /my-test-org/my-sub-org ~sampel] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs (make-pset:smart ~[~sampel]) ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org [%address my-test-org-id] [%ship ~sampel]]
      ==
  ==
::
++  test-vw-add-member-sub-org-controller  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    =+  [caller-2 ~ id.p:orgs-pact [1 1.000.000] default-town-id 0]
    [fake-sig [%add-member my-test-org-id /my-test-org/my-sub-org ~sampel] -]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs (make-pset:smart ~[~sampel]) ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org [%address my-test-org-id] [%ship ~sampel]]
      ==
  ==
::
++  test-vv-add-member-nonexistent-sub-org  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-member my-test-org-id /my-test-org/not-here ~sampel] my-shell]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-vu-add-member-already-in  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%add-member my-test-org-id / ~hodzod] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %add-tag
          [/my-test-org [%address my-test-org-id] [%ship ~hodzod]]
      ==
  ==
::
::  tests for %del-member
::
++  test-uz-del-member  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%del-member my-test-org-id /my-test-org ~hodzod] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %del-tag
          [/my-test-org [%address my-test-org-id] [%ship ~hodzod]]
      ==
  ==
::
++  test-uy-del-member-empty-path  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%del-member my-test-org-id / ~hodzod] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %del-tag
          [/my-test-org [%address my-test-org-id] [%ship ~hodzod]]
      ==
  ==
::
++  test-uv-del-member-nonexistent-sub-org  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%del-member my-test-org-id /my-test-org/not-here ~sampel] my-shell]
  :*  gas=~
      errorcode=`%6
      modified=`~
      burned=`~
      events=`~
  ==
::
++  test-uu-del-member-not-in  ^-  test-txn
  :^    chain
      [sequencer default-town-id batch=1 eth-block-height=0]
    [fake-sig [%del-member my-test-org-id / ~sampel] my-shell]
  :*  gas=~
      errorcode=`%0
      ::  modified the org
      :-  ~
      %-  make-chain-state
      :_  ~
      %-  my-test-org
      :*  'my-test-org'
          /
          `'an org controlled by 0xd387...'
          addr-1:zigs
          (make-pset:smart ~[~hodzod ~walrus])
          %-  make-pmap:smart
          :~  :-  'my-sub-org'
              ['my-sub-org' /my-test-org ~ addr-2:zigs ~ ~]
      ==  ==
      burned=`~
      ::  events
      :-  ~
      :~  :+  id.p:orgs-pact  %del-tag
          [/my-test-org [%address my-test-org-id] [%ship ~sampel]]
      ==
  ==
--