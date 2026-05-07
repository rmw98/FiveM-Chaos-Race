document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById('ghost-container');
    const racersList = document.getElementById('racers-list');
    const hauntsList = document.getElementById('haunts-list');
    const selectedRacerSpan = document.getElementById('selected-racer');
    const selectedHauntSpan = document.getElementById('selected-haunt');
    const hauntCostSpan = document.getElementById('haunt-cost');
    const purchaseButton = document.getElementById('purchase-button');

    let currentSelection = {
        racer: null,
        haunt: null
    };

    // Listen for messages from the Lua script
    window.addEventListener('message', (event) => {
        const data = event.data;

        // This is the new, improved structure that handles each action separately.
        if (data.action === 'showUI') {
            updateRacers(data.racers);
            updateHaunts(data.haunts); // This is safe because 'showUI' always sends haunts.
            container.style.display = 'flex';
        } 
        else if (data.action === 'hideUI') {
            container.style.display = 'none';
        } 
        else if (data.action === 'updateRacers') {
            // This new block specifically handles ONLY racer updates.
            // It does NOT call updateHaunts(). This is the core of the fix.
            updateRacers(data.racers);
        }
    });

    function updateRacers(racers) {
        racersList.innerHTML = '';
        racers.forEach(racer => {
            const item = document.createElement('div');
            item.className = 'list-item';
            item.textContent = racer.name;
            item.dataset.id = racer.id;
            item.addEventListener('click', () => selectRacer(item, racer));
            racersList.appendChild(item);
        });
        // If our currently selected racer is no longer in the list, clear the selection
        if (currentSelection.racer && !racers.some(r => r.id === currentSelection.racer.id)) {
            selectRacer(null, null);
        }
    }

    function updateHaunts(haunts) {
        hauntsList.innerHTML = '';
        haunts.forEach(haunt => {
            const item = document.createElement('div');
            item.className = 'list-item';
            item.dataset.id = haunt.name; // Use name as a unique ID for the haunt
            item.innerHTML = `${haunt.name} <span class="haunt-cost">$${haunt.cost}</span>`;
            item.addEventListener('click', () => selectHaunt(item, haunt));
            hauntsList.appendChild(item);
        });
    }

    function selectRacer(element, racer) {
        // Un-select previous
        document.querySelectorAll('#racers-list .selected').forEach(el => el.classList.remove('selected'));
        // Select new
        if (element) {
            element.classList.add('selected');
        }
        currentSelection.racer = racer;
        selectedRacerSpan.textContent = racer ? racer.name : 'None';
        checkPurchaseAbility();
    }

    function selectHaunt(element, haunt) {
        document.querySelectorAll('#haunts-list .selected').forEach(el => el.classList.remove('selected'));
        if (element) {
            element.classList.add('selected');
        }
        currentSelection.haunt = haunt;
        selectedHauntSpan.textContent = haunt ? haunt.name : 'None';
        hauntCostSpan.textContent = haunt ? `$${haunt.cost}` : '$0';
        checkPurchaseAbility();
    }

    function checkPurchaseAbility() {
        if (currentSelection.racer && currentSelection.haunt) {
            purchaseButton.classList.remove('disabled');
        } else {
            purchaseButton.classList.add('disabled');
        }
    }

    purchaseButton.addEventListener('click', () => {
        if (purchaseButton.classList.contains('disabled')) return;
        
        fetch(`https://gamemanager/purchaseHaunt`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({
                targetServerId: currentSelection.racer.id,
                hauntName: currentSelection.haunt.name
            })
        }).then(resp => resp.json()).then(resp => {
            if (resp.success) {
                // Optionally provide feedback, like a sound effect
            }
        });

        // Deselect haunt after purchase to prevent accidental double-clicks
        selectHaunt(null, null);
    });

    // Handle closing the UI with the Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            fetch(`https://gamemanager/hideUI`, { method: 'POST' });
            container.style.display = 'none';
        }
    });
});
