#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test "tray model helpers" <<'JS'
const tray = requireFromRoot('shell/plugins/bar/widgets/TrayModel.js')

assert(tray.itemNamed({ id: 'dropbox-client' }, 'dropbox'), 'tray matches item ids')
assert(tray.itemNamed({ title: 'Dropbox' }, 'dropbox'), 'tray matches item titles')
assert(tray.itemNamed({ tooltipTitle: 'LocalSend' }, 'localsend'), 'tray matches item tooltips')
assert(!tray.itemNamed({ id: 'nextcloud' }, 'dropbox'), 'tray ignores items named for something else')

const layout = {
  left: [{ id: 'omarchy.menu' }],
  center: [],
  right: [{ id: 'omarchy.dropbox' }, { id: 'omarchy.tray' }]
}

assert(tray.layoutHasWidget(layout, 'omarchy.dropbox'), 'tray finds dedicated dropbox widget in layout')
assert(tray.ownedByOmarchy({ id: 'dropbox' }, layout), 'tray suppresses dropbox when dedicated widget is in bar')
assert(!tray.ownedByOmarchy({ id: 'dropbox' }, { left: [], center: [], right: [] }), 'tray keeps dropbox when dedicated widget is absent')
assert(tray.ownedByOmarchy({ id: 'qlBCprNUqU', title: 'localsend' }, { left: [], center: [], right: [] }), 'tray suppresses localsend regardless of layout')
assert(!tray.ownedByOmarchy({ id: 'nextcloud' }, layout), 'tray keeps unrelated tray items')

const lists = { pinned: ['slack'], hidden: ['discord'] }
assertEqual(tray.classify('slack', lists), 'pinned', 'a pinned item sits on the bar')
assertEqual(tray.classify('discord', lists), 'hidden', 'a hidden item is left out')
assertEqual(tray.classify('signal', lists), 'drawer', 'an item neither pinned nor hidden goes in the drawer')
assertEqual(tray.classify('signal', {}), 'drawer', 'a tray with no settings has a drawer')

const flat = { drawer: false, hidden: ['discord'] }
assertEqual(tray.classify('signal', flat), 'pinned', 'a tray without a drawer keeps an item it does not hide on the bar')
assertEqual(tray.classify('discord', flat), 'hidden', 'a tray without a drawer still leaves out a hidden item')

const saved = tray.withItemLists({ drawer: false, pinned: ['a'], hidden: [] }, ['a', 'b'], ['c'])
assertEqual(JSON.stringify(saved), JSON.stringify({ drawer: false, pinned: ['a', 'b'], hidden: ['c'] }), 'pinning or hiding keeps the tray\'s other settings')
const before = { drawer: false, pinned: [], hidden: [] }
tray.withItemLists(before, ['x'], [])
assertEqual(JSON.stringify(before), JSON.stringify({ drawer: false, pinned: [], hidden: [] }), 'saving leaves the live settings untouched')
JS
