document.addEventListener("DOMContentLoaded", () => {
    const inputs = document.querySelectorAll(".tricks-input");
    inputs.forEach(input => {
        input.addEventListener("keypress", (event) => {
            if (event.key === 'Enter') {
                event.preventDefault();
                const player = event.target.id.split("-")[3]; // Extracts player ID
                const gameId = event.target.getAttribute("game-id");
                const action = event.target.name; // "askForTricks" or "registerTricks"
                const value = event.target.value;
                
                console.log(`Keypress detected for player: ${player}, game: ${gameId}, value: ${value}, action: ${action}`);
                handleInput(action, player, value, gameId);
            }
        });
    });

    if (gameStarted) {
        const gameId = document.querySelector(".points-cell").getAttribute("game-id"); // All inputs have the same game ID
        console.log(gameId)
        fetchLeaderboard(gameId);      
    }
    
});

function handleInput(action, player, value, gameId) {
    if (action === 'askForTricks') {
        askForTricks(player, value, gameId);
    } else if (action === 'registerTricks') {
        registerTricks(player, value, gameId);
    }
}

async function askForTricks(player, tricks, gameId) {
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

async function fetchLeaderboard(gameId) {
  try {
    const response = await fetch(`/api/leaderboard?game_id=${gameId}`);
    const leaderboard = await response.json();

    const leaderboardBody = document.getElementById('leaderboard-body');
    leaderboardBody.innerHTML = '';

    // Leaderboard is sorted already
    // TODO: highlight the rows that have the same points
    Object.entries(leaderboard).forEach(([player, points]) => {
      const row = document.createElement('tr');
      const playerCell = document.createElement('td');
      const pointsCell = document.createElement('td');

      playerCell.textContent = player;
      pointsCell.textContent = points;

      row.appendChild(playerCell);
      row.appendChild(pointsCell);
      leaderboardBody.appendChild(row);
    });
  } catch (error) {
    console.error('Failed to fetch leaderboard', error);
  }
}