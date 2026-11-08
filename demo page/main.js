/**
 * Application Entry Point.
 * Generates interface grid buttons and initializes event coordination.
 */
document.addEventListener('DOMContentLoaded', init);
document.querySelector('#buttons-panel').addEventListener('click', e => handlerClick(e));

function handlerClick(e) {
    let result = `x: ${e.screenX}, y: ${e.screenY}, event.isTrusted = ${e.isTrusted}`;
    console.log(result)
    console.log('–––––––––––––––––––––––––––')

    // UI visual press state toggle
    const elem = e.target;
    elem.classList.add('active');
    setTimeout(() => elem.classList.remove('active'), 150);
}

function init() {
    const panel = document.getElementById('buttons-panel');

    // 1. Dynamically generate grid buttons 1 through 9
    for (let i = 1; i <= 9; i++) {
        const btn = document.createElement('button');
        btn.className = 'btn-item';
        btn.innerHTML = `
            Button ${i}
            <span class="key-hint">[Key ${i}]</span>
        `;
        
        panel.appendChild(btn);
    }

    // 2. Instantiate Coords event dispatcher and keyboard listener
    const coordsApp = new Coords();
}