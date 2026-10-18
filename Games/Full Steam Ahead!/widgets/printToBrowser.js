// For debugging HTML5 builds, send Lua print calls to the browser's console.
printToBrowser = {
	print: function(msg) {
		console.log(msg);
	}
}