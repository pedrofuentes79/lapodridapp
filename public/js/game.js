async function askForTricks(player, tricks) {
    const response = await fetch('/api/ask_for_tricks', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ player, tricks })
    });

    if (response.ok) {
        window.location.reload();
    } else {
        console.error('Failed to ask for tricks');
    }
}

async function registerTricks(player, tricks) {
    const response = await fetch('/api/register_tricks', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ player, tricks })
    });

    if (response.ok) {
        window.location.reload();
    } else {
        console.error('Failed to register tricks');
    }
}