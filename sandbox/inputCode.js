window.inputCode = {
	getCode: function()
	{
        if (typeof parent.getCode === "function") {
    		return parent.getCode();
        } else {
            console.log( "The sandbox app can't be run directly. You need to run it via Iframe." );
			return false;
        }
	},
}
