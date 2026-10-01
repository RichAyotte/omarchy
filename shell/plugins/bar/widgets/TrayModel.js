function text(value) {
  return String(value || "").toLowerCase()
}

function itemNamed(item, name) {
  if (!item) return false
  return text(item.id).indexOf(name) !== -1
    || text(item.title).indexOf(name) !== -1
    || text(item.tooltipTitle).indexOf(name) !== -1
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (entry && typeof entry === "object") {
    var id = entry.id
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function layoutHasWidget(layout, id) {
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var entries = layout && layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      if (entryId(entries[i]) === id) return true
    }
  }
  return false
}

// LocalSend's item shows no state, offers only Open and Quit, and its primary
// click is a no-op, so Share > Receive is the whole surface. Hiding it by hand
// doesn't stick either: LocalSend picks a fresh tray id every launch.
function ownedByOmarchy(item, layout) {
  return itemNamed(item, "localsend")
    || (layoutHasWidget(layout, "omarchy.dropbox") && itemNamed(item, "dropbox"))
}

function listHas(value, key) {
  if (!Array.isArray(value)) return false
  for (var i = 0; i < value.length; i++) {
    if (String(value[i]) === key) return true
  }
  return false
}

function classify(id, settings) {
  var key = String(id || "")
  var values = settings || {}
  if (listHas(values.hidden, key)) return "hidden"
  if (values.drawer === false || listHas(values.pinned, key)) return "pinned"
  return "drawer"
}

// The entry the tray saves after a pin or hide. Saving replaces the whole
// layout entry, so every other setting on it is carried over.
function withItemLists(settings, pinned, hidden) {
  var next = {}
  for (var key in settings || {}) next[key] = settings[key]
  next.pinned = pinned
  next.hidden = hidden
  return next
}

if (typeof module !== "undefined") {
  module.exports = {
    classify: classify,
    withItemLists: withItemLists,
    itemNamed: itemNamed,
    entryId: entryId,
    layoutHasWidget: layoutHasWidget,
    ownedByOmarchy: ownedByOmarchy
  }
}
