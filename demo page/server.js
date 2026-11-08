/**
 * Server transport class handling HTTP/AJAX requests to the local clicker bridge.
 */
class Server {
	
	constructor(){
		
	}
	
	/**
	 * Initializes server transport logging.
	 */
	init() {
		console.log('Server module initialized');
	}
	
	/**
	 * Instantiates cross-browser XMLHttpRequest object.
	 * @returns {XMLHttpRequest|boolean}
	 */
	initAjax() {
		let Request = false;

		if (window.XMLHttpRequest) {
			/* Gecko-compatible browsers, Safari, Konqueror, Chrome, IE7+ */
			Request = new XMLHttpRequest();
		} else if (window.ActiveXObject) {
			/* Legacy Internet Explorer support */
			try {
				 Request = new ActiveXObject("Microsoft.XMLHTTP");
			} catch (CatchException) {
				 Request = new ActiveXObject("Msxml2.XMLHTTP");
			}
		}
	 
		if (!Request) {
			alert("Failed to initialize XMLHttpRequest object");
			return false;
		}
		
		return Request;
	}
	
	/**
	 * Sends target coordinates to the Clickerlite server via POST AJAX request.
	 * @param {{x: number, y: number}} send_array - Coordinate payload object
	 */
	sendCoords(send_array) {
		let json = JSON.stringify(send_array);
		let url = 'http://127.0.0.1'; // Port and path matching Clickerlite Bridge endpoint
		let request = this.initAjax();	
		
		if (!request) return;
		
		console.log('Dispatching coordinates to server:', json);
		request.responseType = 'text';
		request.open('POST', url, true); 
		request.send(json);
	}
	
	sendJSON() {
		// Reserved for future payload extensions
	}
	
	clear() {
		// Reserved cleanup routine
	}
}