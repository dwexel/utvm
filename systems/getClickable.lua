local getClickable = tiny.processingSystem()
getClickable.filter = tiny.requireAll("onClick")
getClickable.active = false

return getClickable