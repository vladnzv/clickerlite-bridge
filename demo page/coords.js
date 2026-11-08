/**
 * Class for handling keyboard events and calculating element screen coordinates.
 */
class Coords {
	
	constructor(){
		this.SERVER = new Server();
		this.init();
		console.log('Coords module initialized');
	}
	
	/**
	 * Initializes event listeners and starts the server instance.
	 */
	init() {
		this.addX = 0;
		this.addY = 0;
		this.SERVER.init();
		document.addEventListener('keyup', this.dispatcher.bind(this));
	}
	
	/**
	 * Keyboard event dispatcher. Filters keys 1-9 (digit row and numpad).
	 * @param {KeyboardEvent} event 
	 */
	dispatcher(event) {
		let keyNum = null;

		// Check both main digit keys (Digit1..Digit9) and Numpad keys (Numpad1..Numpad9)
		if (event.code.startsWith('Digit') || event.code.startsWith('Numpad')) {
			const num = parseInt(event.key, 10);
			if (num >= 1 && num <= 9) {
				keyNum = num;
			}
		}

		if (keyNum !== null) {
			this.handleKeyButtons(keyNum);
		}
	}
	
	/**
	 * Handles button activation, applies visual feedback, and triggers coordinate calculation.
	 * @param {number} buttonIndex - 1-based index of the button (1-9)
	 */
	handleKeyButtons(buttonIndex) {
		const buttons = document.querySelectorAll('.grid .btn-item');
		const elem = buttons[buttonIndex - 1];
		
		if (!elem) return;

		// Calculate and send target screen coordinates
		const coords = this.getScreenCoords(elem);
		this.SERVER.sendCoords(coords);
	}
	
	/**
	 * Calculates randomized coordinates relative to element bounding rect.
	 * @param {HTMLElement} elem 
	 * @returns {{x: number, y: number}}
	 */
	calcCoords(elem) {
		let btn_coord = elem.getBoundingClientRect();
		
		// Introduce random offset within the element bounds (with 10px inner padding)
		let x = this.addX + btn_coord.left + this.getRandomInRange(10, Math.max(10, btn_coord.width - 10));
		let y = this.addY + btn_coord.top + this.getRandomInRange(10, Math.max(10, btn_coord.height - 10));
		
		return { 'x': Math.round(x), 'y': Math.round(y) };
	}

	/**
	 * Calculates absolute desktop screen coordinates of the element's center point.
	 * Works accurately across non-fullscreen window positions and resizes.
	 * @param {HTMLElement} elem 
	 * @returns {{x: number, y: number}} Absolute screen coordinates
	 */
	getScreenCoords(elem) {
	    const rect = elem.getBoundingClientRect();
	    
	    // Total height of browser UI chrome (tabs bar, address line, window header)
	    const chromeHeight = window.outerHeight - window.innerHeight;
	    
		// Absolute desktop coordinates with random offset inside the element (matching calcCoords logic)
	    const screenX = Math.round(window.screenX + rect.left + this.getRandomInRange(10, Math.max(10, rect.width - 10)));
	    const screenY = Math.round(window.screenY + chromeHeight + rect.top + this.getRandomInRange(10, Math.max(10, rect.height - 10)));	    
	    
		return { x: screenX, y: screenY };
	}
	
	/**
	 * Renders a visual crosshair marker at specified coordinates (debug tool).
	 * @param {{x: number, y: number}} coords 
	 */
	makeCrosshair(coords) {
		if (document.querySelector('#my_cross')) {
			document.querySelector('#my_cross').remove();
		}
		
		let x = coords.x;
		let y = coords.y;
		
		var style_cross_x = `position:absolute; z-index:100; height:20px; width:1px; background-color: #ef4444; top:${y-10}px; left:${x}px; pointer-events:none;`;
		var style_cross_y = `position:absolute; z-index:100; height:1px; width:20px; background-color: #ef4444; top:${y}px; left:${x-10}px; pointer-events:none;`;

		var cross_x = '<div class="cross_x" style="' + style_cross_x + '"></div>';
		var cross_y = '<div class="cross_y" style="' + style_cross_y + '"></div>';
		var cross_elem = '<div id="my_cross">'+cross_x+cross_y+'</div>';
		
		document.querySelector('#root').insertAdjacentHTML('afterBegin', cross_elem);
	}
	
	/**
	 * Helper utility to generate a random integer within a range.
	 * @param {number} min 
	 * @param {number} max 
	 * @returns {number}
	 */
	getRandomInRange(min, max) {
		return Math.floor(Math.random() * (max - min + 1)) + min;
	}
}