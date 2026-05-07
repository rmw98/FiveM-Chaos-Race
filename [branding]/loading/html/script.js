document.addEventListener('DOMContentLoaded', () => {
    const progressBar = document.getElementById('progress-bar');
    const loadingStatus = document.getElementById('loading-status');
    const tipText = document.getElementById('tip-text');
    const music = document.getElementById('bg-music');
    const volumeToggle = document.getElementById('volume-toggle');

    // --- Configuration ---
    const tips = [
        "Use your haunts wisely as a ghost!",
        "The 'Marked Man' effect is relentless. Keep moving!",
        "'Jesus Take The Wheel' might not take you to the finish line.",
        "Watch out for the 'Meteor Shower'! It's a blast.",
        "You can earn Chaos Cash by placing in the top 3.",
        "Don't fall below the speed limit during 'Need for Speed'!",
        "Have you met Walter yet? You will."
    ];

    let currentTipIndex = 0;
    music.volume = 0.2; // Set default volume

    // --- Tip Rotator ---
    setInterval(() => {
        currentTipIndex = (currentTipIndex + 1) % tips.length;
        tipText.style.opacity = 0;
        setTimeout(() => {
            tipText.textContent = tips[currentTipIndex];
            tipText.style.opacity = 1;
        }, 500);
    }, 8000);

    // =================================================================
    //                    THE FINAL, CORRECTED LOGIC
    // =================================================================

    volumeToggle.addEventListener('click', () => {
        // Check if the music is currently paused (it will be on the first click).
        if (music.paused) {
            // If it's paused, this is the FIRST click. Let's play the music.
            music.play();
            music.muted = false; // Ensure it's audible.
            volumeToggle.textContent = 'MUTE'; // Since it's playing, the button's next action is to MUTE.
        } else {
            // If it's already playing, we just toggle the mute state.
            if (music.muted) {
                music.muted = false;
                volumeToggle.textContent = 'MUTE';
            } else {
                music.muted = true;
                volumeToggle.textContent = 'UNMUTE';
            }
        }
    });

    // --- FiveM NUI Handlers (No changes needed here anymore for music) ---
    const handlers = {
        startInitFunction(data) {
            // We no longer need to do anything with music here.
            // The logic is now perfectly self-contained in the click handler.
        },

        loadProgress(data) {
            const percent = data.loadFraction * 100;
            progressBar.style.width = `${percent}%`;
            loadingStatus.textContent = data.loadingText;
        }
    };

    window.addEventListener('message', (event) => {
        const eventName = event.data.eventName;
        if (handlers[eventName]) {
            handlers[eventName](event.data);
        }
    });
});