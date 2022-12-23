local getClickable = tiny.processingSystem()
getClickable.filter = tiny.requireAll("clickable")
getClickable.active = false

return getClickable