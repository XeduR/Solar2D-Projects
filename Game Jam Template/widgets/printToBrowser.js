// For debugging HTML5 builds, sends Lua print() to browser's console (F12).
printToBrowser = {
    print: function(msg) {
        console.log(msg);
    }
}