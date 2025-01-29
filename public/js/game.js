document.addEventListener("DOMContentLoaded", () => {
    const inputs = document.querySelectorAll(".tricks-input");
    const editableElements = document.querySelectorAll(".editable"); 

    // KEYPRESS ENTER SENDS STATE AND MOVES ON TO NEXT INPUT
    inputs.forEach((input, index) => {
        input.addEventListener("keypress", (event) => {
            if (event.key === 'Enter') {
                event.preventDefault();
                const player = event.target.dataset.player;
                const gameId = event.target.dataset.gameid;
                const action = event.target.name; // "askForTricks" or "registerTricks"
                const value = event.target.value;
                
                updateGameState(action, player, value, gameId);
                fetchLeaderboard(gameId);
            }
        });
    });

    // DBLCLICK ON SPAN TURNS INTO INPUT
    editableElements.forEach((element) => {
      element.addEventListener("dblclick", (event) => {
        const span = event.target;
        const player = span.dataset.player;
        const round = span.dataset.round;
        const action = span.dataset.action;
        const value = span.innerText;
        const gameId = span.dataset.gameid;
  
        const input = document.createElement("input");
        input.type = "number";
        input.value = value === "-" ? "" : value;
        input.dataset.player = player;
        input.dataset.round = round;
        input.dataset.action = action;
  
        input.addEventListener("blur", (event) => {
          const newValue = event.target.value;
          span.innerText = newValue === "" ? "-" : newValue;
          span.style.display = "inline";
          input.remove();
          updateGameState(action, player, newValue, gameId);
        });
  
        input.addEventListener("keypress", (event) => {
          if (event.key === 'Enter') {
            input.blur();
          }
        });
  
        span.style.display = "none";
        span.parentNode.insertBefore(input, span);
        input.focus();
      });
    });

  const roundSelector = document.getElementById("current-round-selector");
  roundSelector.addEventListener("change", (event) => {
    const selectedRound = event.target.value;
    updateCurrentRound(selectedRound);
  });
});

function updateCurrentRound(selectedRound) {
  const gameState = gameStateFromDOM();
  gameState.current_round_number = selectedRound;
  updateDOMGameState(gameState);
  console.log(gameState)
  sendGameState(gameState, gameState);
}

function sendGameState(gameState, gameId) {
  console.log('Sending game id', gameId);
  fetch('/api/update_game_state', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ game_state: gameState, game_id: gameId })
  });
}


function updateGameState(action, player, value, gameId) {
  const gameState = gameStateFromDOM();
  round = gameState.rounds[gameState.current_round_number];

  if (action === 'askForTricks') {
    round.asked_tricks[player] = parseInt(value, 10);
  } else if (action === 'registerTricks') {
    round.tricks_made[player] = parseInt(value, 10);
  }

  updateDOMGameState(gameState);
  sendGameState(gameState, gameId);

}


function updateDOMGameState(gameState) {
  document.querySelector('script').innerText = `var gameState = ${JSON.stringify(gameState)};`;
}

function gameStateFromDOM() {
  return JSON.parse(document.querySelector('script').innerText.match(/var gameState = (.*);/)[1]);
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