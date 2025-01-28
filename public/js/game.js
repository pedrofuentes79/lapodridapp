function handleKeyPress(event, player, value, gameId) {
    if (event.key === 'Enter') {
        if (event.target.name === 'askForTricks') {
            askForTricks(player, value, gameId);
        } else if (event.target.name === 'registerTricks') {
            registerTricks(player, value, gameId);
        }
    }
}

async function askForTricks(player, tricks, gameId) {
    console.log('asking for tricks', player, tricks);
    const response = await fetch('/api/ask_for_tricks', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ player, tricks, game_id: gameId })
    });

    if (response.ok) {
        window.location.reload();
    } else {
        console.error('Failed to ask for tricks');
    }
}

async function registerTricks(player, tricks, gameId) {
    const response = await fetch('/api/register_tricks', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ player, tricks, game_id: gameId })
    });

    if (response.ok) {
        window.location.reload();
    } else {
        console.error('Failed to register tricks');
    }
}